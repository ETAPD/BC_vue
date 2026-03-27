<script lang="ts">
import { defineComponent, type PropType } from 'vue'

export default defineComponent({
  name: 'MiniTrendChart',
  props: {
    change: {
      type: Number as PropType<number>,
      required: true,
    },
    seedKey: {
      type: String as PropType<string>,
      required: true,
    },
    width: {
      type: Number as PropType<number>,
      default: 84,
    },
    height: {
      type: Number as PropType<number>,
      default: 28,
    },
    pointsCount: {
      type: Number as PropType<number>,
      default: 8,
    },
    gradientId: {
      type: String as PropType<string>,
      default: '',
    },
  },
  computed: {
    actualGradientId(): string {
      return this.gradientId || `mini-grad-${this.seedKey}`
    },
    points(): Array<{ x: number; y: number }> {
      return this.createPoints()
    },
    linePath(): string {
      return this.points
        .map((pt: { x: number; y: number }, i: number) => `${i === 0 ? 'M' : 'L'}${pt.x},${pt.y}`)
        .join(' ')
    },
    areaPath(): string {
      if (!this.points.length) return ''
      return `${this.linePath} L${this.width},${this.height} L0,${this.height} Z`
    },
    strokeColor(): string {
      return this.change >= 0 ? '#4ade80' : '#fb7185'
    },
    fillColorStart(): string {
      return this.change >= 0 ? '#34d399' : '#fb7185'
    },
  },
  methods: {
    createPoints(): Array<{ x: number; y: number }> {
      const chars = (this.seedKey || 'XX').split('')
      const seed = chars.reduce(
        (acc: number, ch: string, idx: number) => acc + ch.charCodeAt(0) * (idx + 1),
        0,
      )
      const normalized = Math.max(-1, Math.min(1, Number(this.change || 0) / 35))
      const baseStart = 0.52 - normalized * 0.18
      const baseEnd = 0.52 + normalized * 0.18
      const pts: Array<{ x: number; y: number }> = []
      for (let i = 0; i < this.pointsCount; i++) {
        const t = i / (this.pointsCount - 1)
        const wave = Math.sin(t * Math.PI * 2 + seed * 0.07) * 0.09
        const ripple = Math.cos(t * Math.PI * 4 + seed * 0.03) * 0.035
        const trend = baseStart + (baseEnd - baseStart) * t
        const yNorm = Math.max(0.12, Math.min(0.88, trend + wave + ripple))
        pts.push({
          x: Number((t * this.width).toFixed(2)),
          y: Number((yNorm * this.height).toFixed(2)),
        })
      }
      return pts
    },
  },
})
</script>

<template>
  <svg :viewBox="`0 0 ${width} ${height}`" class="mini-trend-chart" preserveAspectRatio="none">
    <defs>
      <linearGradient :id="actualGradientId" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" :stop-color="fillColorStart" stop-opacity="0.28" />
        <stop offset="100%" :stop-color="fillColorStart" stop-opacity="0.03" />
      </linearGradient>
    </defs>
    <path :d="areaPath" :fill="`url(#${actualGradientId})`" />
    <path
      :d="linePath"
      fill="none"
      :stroke="strokeColor"
      stroke-width="2.2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  </svg>
</template>

<style scoped>
.mini-trend-chart {
  display: block;
}
</style>
