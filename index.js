import express from "express";
import axios from "axios";

const app = express();
const PORT = 3000;

app.use(express.static("public"));

app.get("/", async (req, res) => {
  try {
    const result = await axios.get("https://secrets-api.appbrewery.com/random");
    res.render("index.ejs", {
      secret: result.data.secret,
      user: result.data.username,
    });
  } catch (error) {
    console.log(error.response.data);
    res.status(500);
  }
});

app.listen(PORT, '0.0.0.0', () => { 
  console.log(`Server is running on port ${PORT}.`); 
});
