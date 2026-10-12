import { http } from '@kit.NetworkKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';
import {
  TongueImageRecord,
  TongueImageQualityStatus,
  TongueAnalysisStatus,
  TongueObservationNote
} from '../model/ProfileModels';

// ==================== 接口声明 ====================

interface TongueImagePayload {
  id: number;
  userId: number;
  assetId: string;
  imageUrl: string;
  thumbnailUrl: string;
  source: string;
  qualityStatus: string;
  qualityNote: string;
  analysisStatus: string;
  analysisId: string;
  modelVersion: string;
  tongueColor: string;
  tongueCoating: string;
  tongueDryness: string;
  tongueShape: string;
  coatingThickness: string;
  coatingColor: string;
  constitutionSuggestion: string;
  healthAdvice: string;
  warningSigns: string;
  analysisNote: string;
  capturedAt: string;
  uploadedAt: string;
  analyzedAt: string;
  createTime: string;
  isDeleted: number;
}

interface ApiListResponse {
  success: boolean;
  message: string;
  data: TongueImagePayload[];
}

interface ApiSingleResponse {
  success: boolean;
  message: string;
  data: TongueImagePayload;
}

interface ApiBoolResponse {
  success: boolean;
  message: string;
}

interface Base64Result {
  data: string;
  contentType: string;
  filename: string;
}

interface AnalyzeBase64Body {
  base64Data: string;
  filename: string;
  contentType: string;
  source: string;
}

// ==================== 服务方法 ====================

/**
 * 获取舌象图片列表
 */
export function fetchTongueImageList(): Promise<TongueImageRecord[]> {
  return requestJson(buildApiUrl('/api/tongue-image/list'), http.RequestMethod.GET, null)
    .then((responseText: string) => {
      const payload = JSON.parse(responseText) as ApiListResponse;
      if (!payload.success) {
        throw new Error(payload.message || '服务器返回失败状态');
      }
      if (!payload.data) {
        const result: TongueImageRecord[] = [];
        return result;
      }
      const resultList: TongueImageRecord[] = [];
      for (let i = 0; i < payload.data.length; i++) {
        resultList.push(mapTongueImageFromPayload(payload.data[i]));
      }
      return resultList;
    });
}

/**
 * 获取单张舌象图片详情
 */
export function fetchTongueImageDetail(id: string): Promise<TongueImageRecord> {
  return requestJson(buildApiUrl(`/api/tongue-image/${id}`), http.RequestMethod.GET, null)
    .then((responseText: string) => {
      const payload = JSON.parse(responseText) as ApiSingleResponse;
      if (!payload.success || !payload.data) {
        throw new Error(payload.message || '获取详情失败');
      }
      return mapTongueImageFromPayload(payload.data);
    });
}

/**
 * 上传舌象图片并进行AI分析（使用Base64方式）
 * @param imageUri 本地图片URI
 * @param source 来源：CAMERA / ALBUM
 */
export function uploadAndAnalyzeTongueImage(
  imageUri: string,
  source: 'CAMERA' | 'ALBUM'
): Promise<TongueImageRecord> {
  return readFileAsBase64(imageUri).then((base64Result: Base64Result) => {
    const body: AnalyzeBase64Body = {
      base64Data: base64Result.data,
      filename: base64Result.filename,
      contentType: base64Result.contentType,
      source: source
    };
    return requestJson(
      buildApiUrl('/api/tongue-image/analyze-base64'),
      http.RequestMethod.POST,
      body
    );
  }).then((responseText: string) => {
    const payload = JSON.parse(responseText) as ApiSingleResponse;
    if (!payload.success || !payload.data) {
      throw new Error(payload.message || '上传分析失败');
    }
    return mapTongueImageFromPayload(payload.data);
  });
}

/**
 * 重新分析舌象图片
 */
export function reanalyzeTongueImage(id: string): Promise<TongueImageRecord> {
  return requestJson(
    buildApiUrl(`/api/tongue-image/${id}/reanalyze`),
    http.RequestMethod.POST,
    null
  ).then((responseText: string) => {
    const payload = JSON.parse(responseText) as ApiSingleResponse;
    if (!payload.success || !payload.data) {
      throw new Error(payload.message || '重新分析失败');
    }
    return mapTongueImageFromPayload(payload.data);
  });
}

/**
 * 删除舌象图片
 */
export function deleteTongueImage(id: string): Promise<boolean> {
  return requestJson(
    buildApiUrl(`/api/tongue-image/${id}`),
    http.RequestMethod.DELETE,
    null
  ).then((responseText: string) => {
    const payload = JSON.parse(responseText) as ApiBoolResponse;
    return payload.success === true;
  });
}

// ==================== 文件读取和Base64 ====================

/**
 * 读取文件并转换为Base64
 */
function readFileAsBase64(uri: string): Promise<Base64Result> {
  return new Promise((resolve: (result: Base64Result) => void, reject: (err: Error) => void) => {
    try {
      const filename = extractFilename(uri);
      const contentType = guessContentType(filename);

      // 使用 fs.open 打开文件，然后读取
      fs.open(uri, fs.OpenMode.READ_ONLY).then((file: fs.File) => {
        return fs.stat(file.fd).then((stat: fs.Stat) => {
          const fileSize: number = stat.size;
          const buffer = new ArrayBuffer(fileSize);
          return fs.read(file.fd, buffer).then(() => {
            fs.close(file.fd);
            const base64Str = arrayBufferToBase64(buffer);
            const result: Base64Result = {
              data: base64Str,
              contentType: contentType,
              filename: filename
            };
            resolve(result);
          });
        });
      }).catch((err: Error) => {
        reject(new Error('读取图片文件失败: ' + err.message));
      });
    } catch (err) {
      reject(new Error('读取图片失败: ' + (err as Error).message));
    }
  });
}

function extractFilename(uri: string): string {
  const lastSlash = uri.lastIndexOf('/');
  if (lastSlash >= 0 && lastSlash < uri.length - 1) {
    return uri.substring(lastSlash + 1);
  }
  return 'tongue.jpg';
}

/**
 * ArrayBuffer转Base64（手动实现，兼容ArkTS严格模式）
 */
function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  const bytes = new Uint8Array(buffer);
  const len = bytes.length;
  let result = '';
  let i = 0;

  while (i < len) {
    const b1 = bytes[i];
    const b2 = i + 1 < len ? bytes[i + 1] : 0;
    const b3 = i + 2 < len ? bytes[i + 2] : 0;

    const enc1 = b1 >> 2;
    const enc2 = ((b1 & 0x03) << 4) | (b2 >> 4);
    const enc3 = ((b2 & 0x0F) << 2) | (b3 >> 6);
    const enc4 = b3 & 0x3F;

    result += BASE64_CHARS.charAt(enc1);
    result += BASE64_CHARS.charAt(enc2);

    if (i + 1 < len) {
      result += BASE64_CHARS.charAt(enc3);
    } else {
      result += '=';
    }
    if (i + 2 < len) {
      result += BASE64_CHARS.charAt(enc4);
    } else {
      result += '=';
    }
    i += 3;
  }
  return result;
}

function guessContentType(filename: string): string {
  const lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  return 'image/jpeg';
}

// ==================== HTTP请求 ====================

function requestJson(url: string, method: http.RequestMethod, body: Object | null): Promise<string> {
  const config = getApiConfig();
  const request = http.createHttp();
  const headers = buildAuthorizedJsonHeaders();

  let bodyStr: string | null = null;
  if (body != null) {
    bodyStr = JSON.stringify(body);
  }

  return request.request(url, {
    method: method,
    header: headers,
    extraData: bodyStr,
    connectTimeout: config.timeoutMs,
    readTimeout: config.aiTimeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
    }
    return `${response.result}`;
  }).catch((error: Error) => {
    request.destroy();
    return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
  });
}

// ==================== 数据映射 ====================

function mapTongueImageFromPayload(payload: TongueImagePayload): TongueImageRecord {
  let analysisResult: TongueObservationNote | undefined = undefined;
  if (payload.analysisStatus === 'SUCCESS') {
    analysisResult = {
      id: payload.id ? `${payload.id}` : '',
      color: payload.tongueColor || '未见明显异常',
      coating: payload.tongueCoating || '未见明显异常',
      dryness: payload.tongueDryness || '未见明显异常',
      note: buildAnalysisNote(payload),
      recordedAt: payload.analyzedAt || payload.createTime || '',
      imageId: payload.id ? `${payload.id}` : '',
      source: 'AI'
    };
  }

  const srcVal: 'CAMERA' | 'ALBUM' = payload.source === 'ALBUM' ? 'ALBUM' : 'CAMERA';

  const record: TongueImageRecord = {
    id: payload.id ? `${payload.id}` : '',
    ownerId: payload.userId ? `${payload.userId}` : '',
    imageUrl: payload.imageUrl,
    thumbnailUrl: payload.thumbnailUrl,
    imageAssetId: payload.assetId,
    capturedAt: payload.capturedAt || payload.createTime || '',
    uploadedAt: payload.uploadedAt,
    source: srcVal,
    qualityStatus: mapQualityStatus(payload.qualityStatus || 'PENDING'),
    qualityNote: payload.qualityNote,
    analysisStatus: mapAnalysisStatus(payload.analysisStatus || 'PENDING_UPLOAD'),
    analysisId: payload.analysisId,
    analysisResult: analysisResult,
    modelVersion: payload.modelVersion,
    note: payload.analysisNote,
    isDeleted: payload.isDeleted === 1
  };
  return record;
}

function mapQualityStatus(status: string): TongueImageQualityStatus {
  if (status === 'ANALYZABLE') return TongueImageQualityStatus.ANALYZABLE;
  if (status === 'NEED_RETAKE') return TongueImageQualityStatus.NEED_RETAKE;
  return TongueImageQualityStatus.PENDING;
}

function mapAnalysisStatus(status: string): TongueAnalysisStatus {
  if (status === 'UPLOADING') return TongueAnalysisStatus.UPLOADING;
  if (status === 'QUEUED') return TongueAnalysisStatus.QUEUED;
  if (status === 'ANALYZING') return TongueAnalysisStatus.ANALYZING;
  if (status === 'SUCCESS') return TongueAnalysisStatus.SUCCESS;
  if (status === 'FAILED') return TongueAnalysisStatus.FAILED;
  if (status === 'CANCELLED') return TongueAnalysisStatus.CANCELLED;
  return TongueAnalysisStatus.PENDING_UPLOAD;
}

function buildAnalysisNote(payload: TongueImagePayload): string {
  const parts: string[] = [];
  if (payload.tongueShape && payload.tongueShape.length > 0) {
    parts.push(`舌形：${payload.tongueShape}`);
  }
  if (payload.coatingThickness && payload.coatingThickness.length > 0) {
    parts.push(`苔质：${payload.coatingThickness}`);
  }
  if (payload.coatingColor && payload.coatingColor.length > 0) {
    parts.push(`苔色：${payload.coatingColor}`);
  }
  if (payload.constitutionSuggestion && payload.constitutionSuggestion.length > 0) {
    parts.push(`体质倾向：${payload.constitutionSuggestion}`);
  }
  if (payload.healthAdvice && payload.healthAdvice.length > 0) {
    parts.push(`养生建议：${payload.healthAdvice}`);
  }
  if (payload.warningSigns && payload.warningSigns.length > 0) {
    parts.push(`注意事项：${payload.warningSigns}`);
  }
  return parts.join('；');
}
