import "./DataPlaceholder.css";

/**
 * 数据/骨架屏占位符组件。
 *
 * 用途：标记"这里应该有数据渲染（图表/表格/列表）但尚未实现"，
 * 或展示骨架屏动画效果。
 *
 * 使用方式：
 *   <DataPlaceholder
 *     shape="table"
 *     rows={5}
 *     cols={3}
 *     label="六痛点对比表"
 *   />
 */
interface DataPlaceholderProps {
  /** 骨架形状 */
  shape: "table" | "list" | "chart-bar" | "chart-line" | "card-grid" | "timeline";
  /** 行数（table/list/timeline）或卡片数（card-grid） */
  rows?: number;
  /** 列数（仅 table） */
  cols?: number;
  /** 标签说明 */
  label?: string;
  /** 来源标注 */
  source?: string;
}

export function DataPlaceholder({
  shape = "list",
  rows = 4,
  cols = 3,
  label,
  source,
}: DataPlaceholderProps) {
  return (
    <div
      className={`ph-data ph-data--${shape}`}
      data-no-advance
    >
      {/* 骨架屏内容 */}
      {shape === "table" && (
        <div className="ph-data__skeleton">
          <div className="ph-data__header">
            {Array.from({ length: cols }).map((_, i) => (
              <span key={i} className="ph-data__th" />
            ))}
          </div>
          {Array.from({ length: rows }).map((_, i) => (
            <div key={i} className="ph-data__tr">
              {Array.from({ length: cols }).map((_, j) => (
                <span
                  key={j}
                  className="ph-data__td"
                  style={{ width: j === 0 ? "30%" : `${Math.random() * 40 + 20}%` }}
                />
              ))}
            </div>
          ))}
        </div>
      )}

      {shape === "list" && (
        <div className="ph-data__skeleton">
          {Array.from({ length: rows }).map((_, i) => (
            <div key={i} className="ph-data__li">
              <span className="ph-data__dot" />
              <span
                className="ph-data__line"
                style={{ width: `${Math.random() * 40 + 45}%` }}
              />
            </div>
          ))}
        </div>
      )}

      {(shape === "chart-bar" || shape === "chart-line") && (
        <div className="ph-data__skeleton ph-data__chart">
          <div className="ph-data__axis-y">
            {Array.from({ length: 4 }).map((_, i) => (
              <span key={i} className="ph-data__tick" />
            ))}
          </div>
          <div className="ph-data__plot">
            {shape === "chart-bar"
              ? Array.from({ length: Math.min(rows, 8) }).map((_, i) => (
                  <div
                    key={i}
                    className="ph-data__bar"
                    style={{ height: `${Math.random() * 70 + 15}%` }}
                  />
                ))
              : <svg viewBox="0 0 400 120" preserveAspectRatio="none" className="ph-data__svg-line">
                  <path
                    d={Array.from({ length: 12 })
                      .map((_, i) => `${i * 36},${120 - Math.random() * 90 - 15}`)
                      .join(" L")}
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    vectorEffect="non-scaling-stroke"
                  />
                </svg>}
          </div>
        </div>
      )}

      {shape === "card-grid" && (
        <div className="ph-data__grid">
          {Array.from({ length: Math.min(rows, 6) }).map((_, i) => (
            <div key={i} className="ph-data__card">
              <span className="ph-data__card-icon" />
              <span className="ph-data__card-title" />
              <span className="ph-data__card-body" />
            </div>
          ))}
        </div>
      )}

      {shape === "timeline" && (
        <div className="ph-data__skeleton ph-data__timeline">
          {Array.from({ length: rows }).map((_, i) => (
            <div key={i} className="ph-data__tl-item">
              <span className="ph-data__tl-dot" />
              <span className="ph-data__tl-content">
                <span className="ph-data__tl-title" />
                <span className="ph-data__tl-desc" />
              </span>
            </div>
          ))}
        </div>
      )}

      {/* 标签 + 来源 */}
      {(label || source) && (
        <div className="ph-data__label-row">
          {label && <span className="ph-data__label">{label}</span>}
          {source && <span className="ph-data__source">{source}</span>}
        </div>
      )}
    </div>
  );
}
