const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
app.use(cors());

const SAAVN_BASE = 'https://saavn.dev'; 
// public unofficial API (stable & widely used)


// 🔍 Search songs
app.get('/search', async (req, res) => {
  try {
    const q = req.query.q;
    if (!q) return res.status(400).json({ error: 'Query required' });

    const response = await axios.get(
      `${SAAVN_BASE}/api/search/songs?query=${encodeURIComponent(q)}`
    );

    const songs = response.data.data.results.map(song => ({
      id: song.id,
      title: song.name,
      artist: song.primaryArtists,
      image: song.image[2].url,
      streamUrl: song.downloadUrl[4].url, // HIGH QUALITY
    }));

    res.json(songs);
  } catch (e) {
    res.status(500).json({ error: 'Search failed' });
  }
});

// ▶ Get song by ID
app.get('/song/:id', async (req, res) => {
  try {
    const response = await axios.get(
      `${SAAVN_BASE}/api/songs/${req.params.id}`
    );

    const s = response.data.data[0];

    res.json({
      id: s.id,
      title: s.name,
      artist: s.primaryArtists,
      image: s.image[2].url,
      streamUrl: s.downloadUrl[4].url,
      duration: s.duration,
    });
  } catch (e) {
    res.status(500).json({ error: 'Song fetch failed' });
  }
});

app.listen(3000, () =>
  console.log('🎵 Music backend running on http://localhost:3000')
);
