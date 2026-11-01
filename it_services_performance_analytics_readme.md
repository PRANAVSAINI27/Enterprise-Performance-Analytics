# IT Services Performance Analytics (Infosys Case Study)

An end-to-end Data Engineering and Business Intelligence project analyzing 12 years (FY15–FY27) of historical financial, workforce, and operational data for a global IT consulting firm.

## 🛠️ Tech Stack
* **ETL & Data Prep:** Microsoft Excel (Power Query)
* **Database Layer:** SQL (MySQL / SQL Server)
* **Visualization:** Microsoft Power BI (DAX, Data Modeling)

## 📊 Dashboard Highlights
The Power BI report translates messy corporate earnings sheets into four strategic pages:

1. **Financial & Margin Performance:** Tracks top-line revenue growth against cost of sales to monitor operating margins over time.
2. **Workforce & Delivery Efficiency:** Visualizes "Great Resignation" attrition spikes, bench utilization percentages, and the Onsite vs. Offshore delivery mix.
3. **Geographic & Industry Segments:** Uses 100% stacked charts to highlight portfolio diversification across verticals (e.g., Financial Services, Retail).
4. **Client Portfolio & Risk:** Measures sales velocity (new clients) and monitors revenue reliance on Top 5 / Top 10 clients to assess concentration risk.

## 🗄️ Database Architecture
Raw corporate `.xls` files were unpivoted and cleansed into four core SQL fact tables: 
* `fact_financials` | `fact_workforce` | `fact_segments` | `fact_clients`

Custom SQL Views (e.g., `vw_workforce_metrics`) sit on top of these tables to handle dynamic date generation for Power BI's Time Intelligence and enforce strict decimal preservation.

## 🚀 Quick Start
1. **Clone Repo:** 
   ```bash
   git clone https://github.com/yourusername/it-services-performance-analytics.git
   ```
2. **Setup Database:** Execute the SQL scripts in the `sql_scripts/` folder to build tables and views.
3. **Load Data:** Import the clean `.csv` files from the `data/clean/` folder into your SQL database.
4. **Run Dashboard:** Open the `.pbix` file. Go to *Transform Data > Data Source Settings*, point it to your local SQL server, and click Refresh.