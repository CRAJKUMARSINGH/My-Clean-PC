// My Clean PC — Email Reminder Function
// Uses Resend (free tier: 3,000 emails/month)
// Set RESEND_API_KEY in Netlify → Site configuration → Environment variables

const https = require("https");

exports.handler = async (event) => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
  };

  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  if (event.httpMethod !== "POST") {
    return { statusCode: 405, headers, body: JSON.stringify({ error: "Method not allowed" }) };
  }

  let body;
  try {
    body = JSON.parse(event.body || "{}");
  } catch {
    return { statusCode: 400, headers, body: JSON.stringify({ error: "Invalid JSON" }) };
  }

  const { email } = body;

  if (!email || !email.includes("@")) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: "Valid email address required" }) };
  }

  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 503,
      headers,
      body: JSON.stringify({ error: "Email service not configured. Add RESEND_API_KEY to Netlify environment variables." }),
    };
  }

  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
  const cleanDate = nextMonth.toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" });

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Time to clean your PC!</title>
</head>
<body style="margin:0;padding:0;background:#fff8f0;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:520px;margin:32px auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.10);">

    <!-- Header -->
    <div style="background:linear-gradient(135deg,#b91c1c,#ea580c);padding:32px 24px;text-align:center;">
      <div style="font-size:48px;margin-bottom:8px;">🧹</div>
      <h1 style="color:#ffffff;margin:0;font-size:26px;font-weight:800;letter-spacing:-0.5px;">My Clean PC</h1>
      <p style="color:rgba(255,255,255,0.85);margin:6px 0 0;font-size:14px;">Your personal PC cleaning reminder</p>
    </div>

    <!-- Body -->
    <div style="padding:28px 28px 8px;">
      <p style="font-size:18px;font-weight:700;color:#111827;margin:0 0 8px;">Hi Priyanka! 👋</p>
      <p style="font-size:15px;color:#374151;line-height:1.7;margin:0 0 20px;">
        This is your monthly reminder to clean your PC.
        Your next clean is due on
        <strong style="color:#ea580c;">${cleanDate}</strong>.
      </p>

      <!-- CTA -->
      <div style="text-align:center;margin:24px 0;">
        <a href="${process.env.APP_URL || "https://my-clean-pc.netlify.app"}"
           style="display:inline-block;background:linear-gradient(135deg,#ea580c,#b91c1c);color:#ffffff;text-decoration:none;font-size:16px;font-weight:700;padding:14px 36px;border-radius:50px;letter-spacing:0.2px;">
          🧹 Open My Clean PC
        </a>
      </div>

      <!-- Safety note -->
      <div style="background:#f0fdf4;border:1.5px solid #86efac;border-radius:10px;padding:14px 16px;margin:20px 0;">
        <p style="margin:0;font-size:13px;color:#166534;font-weight:600;">
          🔒 As always: your passwords, Downloads folder, and personal files are <strong>NEVER</strong> touched.
          Only junk and temporary files are deleted.
        </p>
      </div>

      <!-- What gets cleaned -->
      <p style="font-size:13px;color:#6b7280;margin:16px 0 4px;font-weight:600;">What the browser cleaner does:</p>
      <ul style="font-size:13px;color:#374151;line-height:2;margin:0 0 16px;padding-left:18px;">
        <li>Removes cached web pages &amp; old website data</li>
        <li>Clears cookies (you may need to log in to some sites again)</li>
        <li>Clears session storage &amp; IndexedDB</li>
        <li>Removes service workers</li>
      </ul>
    </div>

    <!-- Footer -->
    <div style="background:#f9fafb;padding:16px 28px;text-align:center;border-top:1px solid #f3f4f6;">
      <p style="margin:0;font-size:11px;color:#9ca3af;">
        Made with ❤️ for Priyanka &nbsp;·&nbsp;
        You're getting this because you signed up for cleaning reminders.<br>
        Open the app and remove your email to stop these reminders.
      </p>
    </div>

  </div>
</body>
</html>`;

  const payload = JSON.stringify({
    from: "My Clean PC <onboarding@resend.dev>",
    to: [email],
    subject: `🧹 PC cleaning due ${cleanDate} — My Clean PC`,
    html,
  });

  try {
    const result = await new Promise((resolve, reject) => {
      const req = https.request(
        {
          hostname: "api.resend.com",
          path: "/emails",
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
            "Content-Length": Buffer.byteLength(payload),
          },
        },
        (res) => {
          let data = "";
          res.on("data", (chunk) => (data += chunk));
          res.on("end", () => resolve({ status: res.statusCode, body: data }));
        }
      );
      req.on("error", reject);
      req.write(payload);
      req.end();
    });

    if (result.status >= 200 && result.status < 300) {
      return { statusCode: 200, headers, body: JSON.stringify({ ok: true, message: "Reminder email sent!" }) };
    } else {
      console.error("Resend error:", result.body);
      return { statusCode: 502, headers, body: JSON.stringify({ error: "Failed to send email. Check your Resend API key." }) };
    }
  } catch (err) {
    console.error("Network error:", err);
    return { statusCode: 500, headers, body: JSON.stringify({ error: "Network error sending email." }) };
  }
};
