-- 舌象图片记录表
-- 存储用户上传的舌象照片及AI分析结果

CREATE TABLE IF NOT EXISTS tongue_image (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL COMMENT '用户ID',
  asset_id VARCHAR(100) NULL COMMENT '图片资源ID',
  image_url VARCHAR(500) NULL COMMENT '图片访问URL',
  thumbnail_url VARCHAR(500) NULL COMMENT '缩略图URL',
  source VARCHAR(20) NOT NULL DEFAULT 'CAMERA' COMMENT '来源：CAMERA相机/ALBUM相册',
  quality_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '质量状态：PENDING待检查/ANALYZABLE可分析/NEED_RETAKE需重拍',
  quality_note VARCHAR(200) NULL COMMENT '质量备注',
  analysis_status VARCHAR(20) NOT NULL DEFAULT 'PENDING_UPLOAD' COMMENT '分析状态：PENDING_UPLOAD待上传/UPLOADING上传中/QUEUED排队中/ANALYZING分析中/SUCCESS成功/FAILED失败/CANCELLED已取消',
  analysis_id VARCHAR(64) NULL COMMENT '分析任务ID',
  model_version VARCHAR(50) NULL COMMENT '模型版本',
  -- 分析结果字段
  tongue_color VARCHAR(50) NULL COMMENT '舌色',
  tongue_coating VARCHAR(50) NULL COMMENT '舌苔',
  tongue_dryness VARCHAR(50) NULL COMMENT '润燥',
  tongue_shape VARCHAR(50) NULL COMMENT '舌形',
  coating_thickness VARCHAR(50) NULL COMMENT '舌苔厚薄',
  coating_color VARCHAR(50) NULL COMMENT '舌苔颜色',
  -- 中医判断
  constitution_suggestion VARCHAR(500) NULL COMMENT '体质倾向判断',
  health_advice VARCHAR(1000) NULL COMMENT '养生建议',
  warning_signs VARCHAR(500) NULL COMMENT '注意事项/危险信号',
  analysis_note VARCHAR(500) NULL COMMENT '分析备注',
  -- 时间
  captured_at VARCHAR(30) NULL COMMENT '拍摄时间',
  uploaded_at VARCHAR(30) NULL COMMENT '上传时间',
  analyzed_at VARCHAR(30) NULL COMMENT '分析完成时间',
  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除',
  CONSTRAINT fk_tongue_image_user
    FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='舌象图片记录表';

CREATE INDEX idx_tongue_image_user ON tongue_image(user_id);
CREATE INDEX idx_tongue_image_status ON tongue_image(analysis_status);
