# Biodiversity Shiny App

[![Link to live dashboard](https://img.shields.io/badge/Live%20Dashboard-link_placeholder-brightgreen)](link_placeholder)

![Demo GIF](gif_placeholder)

**Description:**

This is a Shiny dashboard designed to visualize biodiversity data across various countries using a dataset of 200,000 records. The application provides several interactive components to explore and understand the data:

* **Interactive Map:** Displays the geographical distribution of biodiversity occurrences. Clicking on markers reveals additional information about specific records.
* **Time Series Plot:** Allows users to observe the number of species found over different time periods.
* **Filterable Table:** Provides a tabular view of the data with the ability to apply filters for specific exploration.
* **AI Playground:** A dedicated tab leveraging AI (based on [r-sidebot](https://github.com/jcheng5/r-sidebot)) to enable users to filter data using natural language queries, generate insights, and create custom plots.

**Dashboard Features:**

1.  **Performance with DuckDB:** Utilizes DuckDB for efficient and fast data processing, enabling quick loading and filtering of the large dataset.
2.  **Fast Filtering:** Implements `shinyWidgets::pickerInput` for a responsive and user-friendly data filtering experience.
3.  **Interactive Map Markers:** Clickable map markers display extra details about each biodiversity record.
4.  **Shiny Server Deployment:** Designed for deployment using Shiny Server.
5.  **Fully Dockerized:** The entire project is containerized using Docker, ensuring consistent operation across any machine with Docker installed.
6.  **AI Playground:** A dedicated tab for AI-powered data exploration, allowing natural language queries for filtering, insight generation, and plotting (inspired by [r-sidebot](https://github.com/jcheng5/r-sidebot)). While the core functionality is demonstrated, further improvements to this module are possible.
7.  **Light and Dark Themes:** Offers both light and dark visual themes for user preference.
8.  **Automatic Data Conversion:** Automatically converts the input CSV data to a DuckDB database upon startup, eliminating manual data processing steps for the user.
9.  **Caching Mechanism:** Implements caching strategies to optimize Docker build times.

**How to Run:**

**One-time Setup:**

1.  **Edit `.env` file:**
    * Locate the `.env` file in the project directory.
    * Change the value of `OPENAI_API_KEY` to your OpenAI API key.
    * Update the value of `CSV_DATA_LOCATION` to the absolute or relative path of your `occurence.csv` file.
    * (Optional) If you wish to utilize Docker build caching, modify `HOST_MACHINE_CACHE_LOCATION` to a local directory on your machine where Docker can store cache volumes.

2.  **Run Docker Compose:**
    Open your terminal or command prompt, navigate to the project directory, and execute the following command:

    ```bash
    docker-compose up -d --build
    ```

    This command will build the Docker image (if necessary) and start the Shiny application in detached mode.

3.  **Access the Dashboard:**
    Once the Docker containers are running, you can access the dashboard in your web browser at the following URL:

    ```
    http://localhost:3839/
    ```

**Reference to Previous Work:**

Three to four years ago, I developed another dashboard for a similar biodiversity visualization task. You can find the code for that older project here: [https://github.com/KryeKuzhinieri/biodiversity-shiny-app](https://github.com/KryeKuzhinieri/biodiversity-shiny-app)
