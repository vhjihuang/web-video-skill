import "./AudioPlaceholder.css";

/**
 * 音频占位符组件。
 *
 * 用途：标记"这个 step 应该有口播音频但尚未合成"，
 * 或展示音频元数据（时长/状态）。
 *
 * 使用方式：
 *   <AudioPlaceholder
 *     duration={8.5}
 *     status="missing"
 *     narrationPreview="你有没有遇到过这种情况？"
 *   />
 */
interface AudioPlaceholderProps {
  /** 音频时长（秒） */
  duration?: number;
  /** 当前状态 */
  status?: "missing" | "pending" | "ready" | "error";
  /** 口播文本预览（前 30 字） */
  narrationPreview?: string;
  /** 是否紧凑模式（小尺寸） */
  compact?: boolean;
}

export function AudioPlaceholder({
  duration,
  status = "missing",
  narrationPreview,
  compact = false,
}: AudioPlaceholderProps) {
  const secs = duration?.toFixed(1) ?? "--.-";

  return (
    <div
      className={`ph-audio ph-audio--${status}${compact ? " ph-audio--compact" : ""}`}
      data-no-advance
    >
      {/* 波形模拟 */}
      <div className="ph-audio__waveform">
        {Array.from({ length: 24 }).map((_, i) => (
          <span
            key={i}
            className="ph-audio__bar"
            style={{
              height: `${Math.random() * 60 + 20}%`,
              animationDelay: `${i * 40}ms`,
            }}
          />
        ))}
      </div>

      {/* 元数据 */}
      <div className="ph-audio__meta">
        <span className="ph-audio__duration">{secs}s</span>
        <span className="ph-audio__status">{status}</span>
      </div>

      {/* 文本预览 */}
      {narrationPreview && (
        <p className="ph-audio__preview">
          &ldquo;{narrationPreview.length > 35
            ? `${narrationPreview.slice(0, 35)}…`
            : narrationPreview}&rdquo;
        </p>
      )}
    </div>
  );
}
