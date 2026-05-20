import React, { type CSSProperties, type ReactNode } from "react";
import "./ImagePlaceholder.css";

/**
 * 图片/视觉素材占位符组件。
 *
 * 用途：章节开发时标记"这里应该有一张图"，替代 fake 数据 / 假 logo。
 * 当真实素材就位后，替换为 <img> 或 SVG。
 *
 * 使用方式：
 *   <ImagePlaceholder
 *     aspectRatio="16:9"
 *     description="医疗诊断流程四步图"
 *     source="article §2 L67-77"
 *     type="diagram"
 *   />
 */
interface ImagePlaceholderProps {
  /** 画幅比例，决定占位框形状 */
  aspectRatio: "16:9" | "4:3" | "1:1" | "icon" | "banner";
  /** 占位描述（给 agent / 用户看的文字） */
  description: string;
  /** 素材来源标注（对应 MATERIAL-INDEX 或 article 位置） */
  source?: string;
  /** 素材类型标签（影响显示样式） */
  type?: "photo" | "diagram" | "chart" | "screenshot" | "icon" | "illustration";
  /** 自定义尺寸覆盖（px），不传则按 aspectRatio 自动计算 */
  width?: number;
  height?: number;
}

const ASPECT_MAP: Record<ImagePlaceholderProps["aspectRatio"], { w: number; h: number; label: string }> = {
  "16:9":  { w: 960, h: 540, label: "16:9" },
  "4:3":   { w: 720, h: 540, label: "4:3" },
  "1:1":   { w: 400, h: 400, label: "1:1" },
  "icon":  { w: 120, h: 120, label: "icon" },
  "banner": { w: 1200, h: 200, label: "banner" },
};

export function ImagePlaceholder({
  aspectRatio = "16:9",
  description,
  source,
  type = "photo",
  width,
  height,
}: ImagePlaceholderProps) {
  const dim = ASPECT_MAP[aspectRatio];
  const style: CSSProperties = {
    ...(width != null ? { width } : { width: dim.w }),
    ...(height != null ? { height } : { height: dim.h }),
  };

  return (
    <div
      className={`ph-img ph-img--${aspectRatio.replace(':', '-')} ph-img--${type}`}
      style={style}
      data-no-advance
    >
      <div className="ph-img__inner">
        <span className="ph-img__type">{type}</span>
        <span className="ph-img__ratio">{dim.label}</span>
        <p className="ph-img__desc">{description}</p>
        {source && <span className="ph-img__src">{source}</span>}
      </div>
    </div>
  );
}
