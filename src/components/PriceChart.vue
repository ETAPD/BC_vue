<script lang="ts">
import { defineComponent, type PropType } from 'vue'

type PricePoint = { price: number; recorded_at: string }

function at(arr: PricePoint[], i: number): PricePoint {
  return arr[i] ?? { price: 0, recorded_at: '' }
}

export default defineComponent({
  name: 'PriceChart',
  props: {
    prices: {
      type: Array as PropType<PricePoint[]>,
      required: true,
    },
    width: { type: Number, default: 700 },
    height: { type: Number, default: 260 },
    padding: { type: Number, default: 40 },
    gradientId: { type: String, default: 'priceChartGrad' },
    showTooltip: { type: Boolean, default: true },
    showGridLabels: { type: Boolean, default: true },
    showGridLines: { type: Boolean, default: true },
    gridLineCount: { type: Number, default: 4 },
  },
  data() {
    return {
      tooltip: {
        show: false,
        x: 0,
        y: 0,
        price: 0,
        date: '',
        change: 0,
        changePct: '0',
      } as {
        show: boolean
        x: number
        y: number
        price: number
        date: string
        change: number
        changePct: string
      },
    }
  },
  computed: {
    priceValues(): number[] {
      return this.prices.map((p) => p.price)
    },
    minPrice(): number {
      return this.priceValues.length ? Math.min(...this.priceValues) : 0
    },
    maxPrice(): number {
      return this.priceValues.length ? Math.max(...this.priceValues) : 0
    },
    priceChange(): number {
      const pts = this.prices
      if (pts.length < 2) return 0
      return at(pts, pts.length - 1).price - at(pts, 0).price
    },
    priceChangePct(): string {
      const pts = this.prices
      if (pts.length < 2) return '0.0'
      const first = at(pts, 0)
      const last = at(pts, pts.length - 1)
      if (first.price === 0) return '0.0'
      return (((last.price - first.price) / first.price) * 100).toFixed(2)
    },
    chartLinePath(): string {
      const pts = this.prices
      if (pts.length < 2) return ''
      const rangeP = this.maxPrice - this.minPrice || 1
      const w = this.width - this.padding * 2
      const h = this.height - this.padding * 2
      return pts
        .map((p, i) => {
          const x = this.padding + (i / (pts.length - 1)) * w
          const y = this.padding + h - ((p.price - this.minPrice) / rangeP) * h
          return `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`
        })
        .join(' ')
    },
    chartAreaPath(): string {
      if (!this.chartLinePath) return ''
      const w = this.width - this.padding * 2
      const lastX = this.padding + w
      const baseY = this.height - this.padding
      return `${this.chartLinePath} L${lastX},${baseY} L${this.padding},${baseY} Z`
    },
    gridLines(): { y: number; price: number; change: number; changePct: string }[] {
      const pts = this.prices
      if (pts.length < 2) return []
      const h = this.height - this.padding * 2
      const firstPrice = at(pts, 0).price
      const lines: { y: number; price: number; change: number; changePct: string }[] = []
      for (let i = 0; i <= this.gridLineCount; i++) {
        const price = this.maxPrice - (i / this.gridLineCount) * (this.maxPrice - this.minPrice)
        const y = this.padding + (i / this.gridLineCount) * h
        const change = price - firstPrice
        const changePct = firstPrice === 0 ? '0.0' : ((change / firstPrice) * 100).toFixed(2)
        lines.push({ y, price, change, changePct })
      }
      return lines
    },
    strokeColor(): string {
      return this.priceChange >= 0 ? '#22c55e' : '#ef4444'
    },
  },
  methods: {
    onMouseMove(event: MouseEvent) {
      if (!this.showTooltip) return
      const svg = event.currentTarget as SVGSVGElement
      if (!svg || this.prices.length < 2) return
      const rect = svg.getBoundingClientRect()
      const relX = event.clientX - rect.left
      const svgX = (relX / rect.width) * this.width
      const w = this.width - this.padding * 2
      let idx = Math.round(((svgX - this.padding) / w) * (this.prices.length - 1))
      idx = Math.max(0, Math.min(this.prices.length - 1, idx))
      const pt = at(this.prices, idx)
      const firstPrice = at(this.prices, 0).price
      const change = pt.price - firstPrice
      const changePct = firstPrice === 0 ? '0.0' : ((change / firstPrice) * 100).toFixed(2)
      const rangeP = this.maxPrice - this.minPrice || 1
      const h = this.height - this.padding * 2
      const px = this.padding + (idx / (this.prices.length - 1)) * w
      const py = this.padding + h - ((pt.price - this.minPrice) / rangeP) * h
      this.tooltip = {
        show: true,
        x: px,
        y: py,
        price: pt.price,
        date: new Date(pt.recorded_at).toLocaleString('sk-SK'),
        change,
        changePct,
      }
    },
    onMouseLeave() {
      this.tooltip.show = false
    },
    formatCurrency(n: number) {
      return n.toLocaleString('sk-SK', { style: 'currency', currency: 'USD' })
    },
  },
})
</script>

<template>
  <div v-if="prices.length < 2" class="chart-empty">
    <slot name="empty">Cenové údaje nie sú k dispozícii</slot>
  </div>
  <div v-else class="chart-container">
    <svg
      :viewBox="`0 0 ${width} ${height}`"
      class="price-chart"
      preserveAspectRatio="none"
      @mousemove="onMouseMove"
      @mouseleave="onMouseLeave"
    >
      <defs>
        <linearGradient :id="gradientId" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" :stop-color="strokeColor" stop-opacity="0.3" />
          <stop offset="100%" :stop-color="strokeColor" stop-opacity="0.02" />
        </linearGradient>
      </defs>
      <!-- Grid lines -->
      <template v-if="showGridLines">
        <template v-for="(gl, gi) in gridLines" :key="'grid' + gi">
          <line
            :x1="padding"
            :y1="gl.y"
            :x2="width - padding"
            :y2="gl.y"
            stroke="rgba(59,130,246,0.08)"
            stroke-width="1"
          />
        </template>
      </template>
      <!-- Area fill -->
      <path :d="chartAreaPath" :fill="`url(#${gradientId})`" />
      <!-- Line -->
      <path
        :d="chartLinePath"
        fill="none"
        :stroke="strokeColor"
        stroke-width="2"
        stroke-linejoin="round"
      />
      <!-- Tooltip crosshair -->
      <template v-if="showTooltip && tooltip.show">
        <line
          :x1="tooltip.x"
          :y1="padding"
          :x2="tooltip.x"
          :y2="height - padding"
          stroke="rgba(255,255,255,0.25)"
          stroke-width="1"
          stroke-dasharray="3,3"
        />
        <line
          :x1="padding"
          :y1="tooltip.y"
          :x2="width - padding"
          :y2="tooltip.y"
          stroke="rgba(255,255,255,0.15)"
          stroke-width="1"
          stroke-dasharray="3,3"
        />
        <circle
          :cx="tooltip.x"
          :cy="tooltip.y"
          r="4"
          :fill="tooltip.change >= 0 ? '#22c55e' : '#ef4444'"
          stroke="white"
          stroke-width="1.5"
        />
      </template>
    </svg>
    <!-- Grid price labels (right side) -->
    <div v-if="showGridLabels" class="chart-grid-labels">
      <div
        v-for="(gl, gi) in gridLines"
        :key="'gl' + gi"
        class="grid-label"
        :style="{ top: (gl.y / height) * 100 + '%' }"
      >
        <span class="gl-price">{{ formatCurrency(gl.price) }}</span>
        <span :class="['gl-change', gl.change >= 0 ? 'up' : 'down']">
          {{ gl.change >= 0 ? '+' : '' }}{{ gl.changePct }}%
        </span>
      </div>
    </div>
    <!-- Tooltip box -->
    <div
      v-if="showTooltip && tooltip.show"
      class="chart-tooltip"
      :style="{ left: Math.min(88, Math.max(12, (tooltip.x / width) * 100)) + '%' }"
    >
      <span class="ct-price">{{ formatCurrency(tooltip.price) }}</span>
      <span :class="['ct-change', tooltip.change >= 0 ? 'up' : 'down']">
        {{ tooltip.change >= 0 ? '+' : '' }}{{ formatCurrency(tooltip.change) }} ({{
          tooltip.changePct
        }}%)
      </span>
      <span class="ct-date">{{ tooltip.date }}</span>
    </div>
    <!-- Simple min/max labels (optional slot override) -->
    <div v-if="!showGridLabels" class="chart-labels">
      <span>{{ formatCurrency(maxPrice) }}</span>
      <span>{{ formatCurrency(minPrice) }}</span>
    </div>
  </div>
</template>

<style scoped>
.chart-container {
  position: relative;
}

.price-chart {
  width: 100%;
  height: v-bind('height + "px"');
  background: rgba(59, 130, 246, 0.02);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
}

.chart-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 200px;
  color: var(--color-text-muted);
  font-size: 0.9rem;
}

/* Grid price labels */
.chart-grid-labels {
  position: absolute;
  top: 0;
  right: 8px;
  bottom: 0;
  pointer-events: none;
}

.grid-label {
  position: absolute;
  right: 0;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 1px;
  background: var(--color-background-soft);
  padding: 0 4px;
  border-radius: 3px;
}

.gl-price {
  font-size: 0.62rem;
  color: var(--color-text-muted);
  font-weight: 600;
  white-space: nowrap;
}

.gl-change {
  font-size: 0.58rem;
  font-weight: 700;
  white-space: nowrap;
}

/* Chart Tooltip */
.chart-tooltip {
  position: absolute;
  top: -8px;
  transform: translateX(-50%);
  background: var(--color-background);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.45rem 0.65rem;
  pointer-events: none;
  z-index: 10;
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
  min-width: 140px;
}

.ct-price {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--color-white);
}

.ct-change {
  font-size: 0.75rem;
  font-weight: 600;
}

.ct-date {
  font-size: 0.65rem;
  color: var(--color-text-muted);
}

/* Simple labels */
.chart-labels {
  position: absolute;
  top: 0;
  right: 8px;
  bottom: 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 8px 0;
  pointer-events: none;
}

.chart-labels span {
  font-size: 0.6rem;
  color: var(--color-text-muted);
  background: var(--color-background-soft);
  padding: 0 4px;
}

.up {
  color: #22c55e;
}

.down {
  color: #ef4444;
}
</style>
