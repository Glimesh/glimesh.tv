import ApexCharts, { initOnLoad } from 'apexcharts';

export default {
    theme() {
        return this.el.dataset.theme;
    },
    data() {
        return JSON.parse(this.el.dataset.chart);
    },
    mounted() {
        let data = this.data();

        Apex.grid = {
            borderColor: '#191e3a'
        }
        Apex.track = {
            background: '#0e1726',
        }
        Apex.tooltip = {
            theme: this.theme()
        }

        var sLineArea = {
            title: {
                text: data.title,
                offsetY: 10,
                align: 'center',
                floating: true,
                style: {
                    color: 'var(--body-color)',
                    fontFamily: 'Noto Sans',
                    fontWeight: '700',
                    fontSize: '1.25rem'
                }
            },
            chart: {
                foreColor: 'var(--body-color)',
                height: 400,
                type: 'area',
                toolbar: {
                    show: true,
                }
            },
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth'
            },
            series: data.series,
            xaxis: data.label,
            tooltip: {
                x: {
                    format: 'MM/dd/yyyy'
                },
            }
        }

        if ("series_format" in data && data.series_format == "money") {
            sLineArea.yaxis = {
                labels: {
                    formatter: function (value) {
                        return "$" + value;
                    }
                },
            };
        }

        var chart = new ApexCharts(
            this.el,
            sLineArea
        );

        chart.render();
    }
};