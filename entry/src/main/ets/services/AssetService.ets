import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import buffer from '@ohos.buffer';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

export interface UploadResult {
  assetId: string;
  imageUrl: string;
  filename: string;
  size: number;
}

interface UploadRequestPayload {
  filename: string;
  contentType: string;
  base64Data: string;
}

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: Object;
}

interface EmptyBody {}

export function uploadImage(localUri: string): Promise<UploadResult> {
  const fileName = extractFileName(localUri);
  const contentType = inferMimeType(fileName);

  return readFileToBase64(localUri)
    .then((base64Data: string) => {
      const config = getApiConfig();
      const request = http.createHttp();
      const url = buildApiUrl('/api/assets/upload-base64');
      const body: UploadRequestPayload = {
        filename: fileName,
        contentType: contentType,
        base64Data: base64Data
      };
      return request.request(url, {
        method: http.RequestMethod.POST,
        header: buildAuthorizedJsonHeaders(),
        extraData: JSON.stringify(body),
        connectTimeout: config.timeoutMs,
        readTimeout: config.timeoutMs
      }).then((response: http.HttpResponse) => {
        request.destroy();
        if (response.responseCode < 200 || response.responseCode >= 300) {
          return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
        }
        const payload = `${response.result}`;
        const resp = JSON.parse(payload) as ApiResponsePayload;
        if (resp.success !== true) {
          throw new Error(resp.message ? resp.message : 'upload failed');
        }
        if (!resp.data) {
          throw new Error('upload response missing data');
        }
        return resp.data as UploadResult;
      }).catch((error: Error) => {
        request.destroy();
        return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
      });
    });
}

function readFileToBase64(uri: string): Promise<string> {
  return fileIo.stat(uri)
    .then((stat: fileIo.Stat) => {
      const fileSize = stat.size;
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      try {
        const arrayBuffer = new ArrayBuffer(fileSize);
        return fileIo.read(file.fd, arrayBuffer).then(() => {
          const buf = buffer.from(arrayBuffer);
          return buf.toString('base64');
        });
      } finally {
        fileIo.closeSync(file.fd);
      }
    });
}

function extractFileName(uri: string): string {
  const lastSlash = uri.lastIndexOf('/');
  if (lastSlash >= 0 && lastSlash < uri.length - 1) {
    return uri.substring(lastSlash + 1);
  }
  return 'image.jpg';
}

function inferMimeType(fileName: string): string {
  const lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'image/jpeg';
}
