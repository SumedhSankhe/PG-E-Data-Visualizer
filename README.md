# PG&E Data Visualizer

[![CI Status](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/SumedhSankhe/PG-E-Data-Visualizer/actions)
[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0.0-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

An R Shiny application that analyzes smart meter energy data through quality control, anomaly detection, pattern recognition, and cost optimization.

**[Live Demo](https://ssankhe.shinyapps.io/PG-E-Data-Visualizer/)** | [Contributing](CONTRIBUTING.md)

---

## Features

- **Quality Control**: Outlier detection, missing value analysis, and quality scoring
- **Anomaly Detection**: Four algorithms (IQR, Z-Score, STL, Moving Average) with configurable sensitivity
- **Pattern Recognition**: Daily/weekly patterns and k-means load curve clustering
- **Cost Optimization**: Rate plan comparison (TOU, Tiered, EV rates) with savings recommendations
- **Export**: One-click Excel report with all analyses

---

## Quick Start

```bash
git clone https://github.com/SumedhSankhe/PG-E-Data-Visualizer.git
cd PG-E-Data-Visualizer
```

```r
renv::restore()        # Install dependencies
shiny::runApp('.')     # Launch the app
```

---

## Data Format

Upload CSV/TSV files with these required columns:

| Column | Type | Description |
|--------|------|-------------|
| `dttm_start` | DateTime | Timestamp (YYYY-MM-DD HH:MM:SS) |
| `hour` | Numeric | Hour of day (0-23) |
| `value` | Numeric | Energy consumption (kWh) |
| `day` | Numeric | Day identifier |
| `day2` | Numeric | Secondary day identifier |

Sample data is included at `data/meterData.rds`.

---

## Automated Data Updates

PG&E customers can automate daily data fetching from smart meters. See [`docs/automation/`](docs/automation/) for setup instructions.

**Quick option** - Process manual PGE downloads:
```r
Rscript scripts/automation/convert_pge_download_v2.R
```

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**Author**: [Sumedh Sankhe](https://github.com/SumedhSankhe)
