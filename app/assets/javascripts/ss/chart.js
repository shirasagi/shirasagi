import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

globalThis.Chart = Chart;
