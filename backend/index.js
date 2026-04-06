const express = require('express');
const { Pool } = require('pg');
const axios = require('axios');
const cors = require('cors');
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// AI Chat Logic
app.post('/api/chat', async (req, res) => {
    const { message, charName } = req.body;
    try {
        const aiResponse = await axios.post('https://api.together.xyz/v1/chat/completions', {
            model: "meta-llama/Llama-3-70b-chat-hf",
            messages: [
                { role: "system", content: `You are ${charName}, an AI model in the AIC-League. Be engaging and mention your 'locked vault' if appropriate.` },
                { role: "user", content: message }
            ]
        }, { headers: { Authorization: `Bearer ${process.env.TOGETHER_AI_KEY}` } });
        res.json({ reply: aiResponse.data.choices[0].message.content });
    } catch (err) { res.status(500).json({ error: "AI Error" }); }
});

// Secure Content Unlock Logic
app.post('/api/unlock', async (req, res) => {
    const { userId, mediaId } = req.body;
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const user = await client.query('SELECT tokens FROM profiles WHERE id = $1 FOR UPDATE', [userId]);
        const media = await client.query('SELECT * FROM media_vault WHERE id = $1', [mediaId]);

        if (user.rows[0].tokens < media.rows[0].token_price) {
            return res.status(402).json({ error: "Insufficient Tokens" });
        }

        await client.query('UPDATE profiles SET tokens = tokens - $1 WHERE id = $2', [media.rows[0].token_price, userId]);
        await client.query('INSERT INTO transactions (user_id, media_id, amount) VALUES ($1, $2, $3)', [userId, mediaId, media.rows[0].token_price]);
        await client.query('COMMIT');

        // Return the link (In production, wrap this in a Signed URL function)
        res.json({ success: true, url: media.rows[0].high_res_url });
    } catch (err) {
        await client.query('ROLLBACK');
        res.status(500).json({ error: "Transaction Failed" });
    } finally { client.release(); }
});

app.listen(process.env.PORT || 3000);
