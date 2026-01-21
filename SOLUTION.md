# Solution Documentation

## 🏗️ Tech Stack
* **Backend:** Ruby on Rails (API Mode)
* **Frontend:** Next.js with TypeScript
* **Database:** MySQL
* **Infrastructure:** Docker (Database containerized)

**Design Rationale:** The primary driver for this stack was **familiarity and development speed**. For a small-scale project, I acknowledge that a more lightweight approach (such as **Node.js + Express**) would reduce overhead. I chose a **Relational Database (MySQL)** because the IRS dataset is highly structured, defined, and requires consistency.

---

## ⚙️ Data Extraction and Processing

The extraction process is triggered via a `POST /dataset` request. Because downloading and parsing large XML files from the IRS is a long-running task, I implemented an **asynchronous background job pattern**.



1.  **Trigger:** The user sends a POST request.
2.  **Job Spawning:** A background job handles the downloading, extraction, and processing.
3.  **Rationale:** This prevents blocking the main web server, ensuring the UI remains responsive while the heavy data lifting happens in the background.
4.  **Parsing:** The system specifically targets XML return types **990, 990EZ, and 990PF**, as these contain the specific data points required by the technical specs.

---

## 🌐 Data Serving & Frontend

### API Design
I opted for a **RESTful API** due to its simplicity and the fact that there is currently only one client with specific needs. If the project were to scale to multiple clients with varying data requirements, I would consider migrating to **GraphQL**.

### Table View & Company Page
* **Dynamic Table:** Displays all required fields with "N/A" fallbacks for missing data. Includes server-side pagination and business name filtering.
* **Company View:** Displays a historical list of all tax filings under the business. I intentionally kept the data fields consistent with the table view to avoid unnecessary complexity during this phase.

---

## 🔒 Authentication
To secure the data ingestion endpoint, I implemented a custom **API Key** system:

* **Generation:** Keys are generated via the Rails console as 32-byte random strings.
* **Storage:** To follow security best practices, the actual key is **not** stored. Instead, a **SHA256 hash** of the key is saved.
* **Validation:** The system checks the `X-API-Key` header, hashes the incoming value, and compares it to the database record.

---

## 🛠️ Logging and Debugging
To handle the unpredictable nature of external data, I added:
* `error_message` and `error_backtrace` fields in the database tables.
* This allows for granular tracking of which specific XML files failed during the background processing and why.

---

## ⚠️ Limitations and Assumptions
1.  **Domain Knowledge:** No financial analysis was performed on the data.
2.  **Scope:** Sorting per column is not currently implemented.
3.  **Data Uniqueness:** Assumes each row represents a unique EIN and Tax Year combination.
4.  **Optimization:** Database indexes are not yet applied; performance may decrease as the dataset grows.

---

## 🚀 Future Improvements
* **Performance:** Add database indexing and migrate to **PostgreSQL** for faster querying.
* **Containerization:** Containerize the entire application suite (Frontend and Backend), not just the database.
* **Security:** Implement Role-Based Access Control (RBAC) and move API key management to a UI for admins.
* **Observability:** Integrate third-party logging platforms like **Rollbar** or **Bugsnag**.
* **Testing:** Add a full suite of unit and integration tests to ensure data integrity.
