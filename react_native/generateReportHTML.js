export default function generateReportHTML(
  uploadedPhotos,
  roofQuestionnaire,
  summaryText = "",
  clientName = "",
  inspectionDate = new Date().toLocaleDateString()
) {
  const groupPhotosBySection = () => {
    const grouped = {};
    uploadedPhotos.forEach((photo) => {
      if (!grouped[photo.sectionPrefix]) {
        grouped[photo.sectionPrefix] = [];
      }
      grouped[photo.sectionPrefix].push(photo);
    });
    return grouped;
  };

  const groupedPhotos = groupPhotosBySection();

  return `
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8" />
      <title>ClearSky Inspection Report</title>
      <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        h1, h2 { color: #2c3e50; }
        .photo-section { margin-bottom: 30px; }
        .photo-grid { display: flex; flex-wrap: wrap; gap: 10px; }
        .photo-item { width: 48%; }
        img { width: 100%; border-radius: 6px; border: 1px solid #ccc; }
        .caption { font-size: 14px; margin-top: 4px; }
        .questionnaire { background: #f6f6f6; padding: 10px; margin: 20px 0; border-left: 5px solid #2c3e50; }
        .summary { margin-top: 30px; font-style: italic; }
      </style>
    </head>
    <body>
      <h1>Roof Inspection Report</h1>
      <p><strong>Date:</strong> ${inspectionDate}</p>
      <p><strong>Client:</strong> ${clientName || "________________"}</p>

      <h2>Photos</h2>
      ${Object.entries(groupedPhotos)
        .map(
          ([section, photos]) => `
        <div class="photo-section">
          <h3>${section}</h3>
          <div class="photo-grid">
            ${photos
              .map(
                (p) => `
              <div class="photo-item">
                <img src="${p.imageUri}" alt="Photo" />
                <div class="caption">${p.userLabel}</div>
              </div>
            `
              )
              .join("")}
          </div>
        </div>
      `
        )
        .join("")}

      <h2>Roof Questionnaire Summary</h2>
      <div class="questionnaire">
        ${Object.entries(roofQuestionnaire)
          .map(
            ([section, data]) => `
          <h4>${section.toUpperCase()}</h4>
          ${
            typeof data === "object" && !Array.isArray(data)
              ? Object.entries(data)
                  .map(
                    ([key, values]) => `
                <p><strong>${key}:</strong> ${values.join(", ")}</p>
              `
                  )
                  .join("")
              : Array.isArray(data)
              ? `<p>${data.join(", ")}</p>`
              : ""
          }
        `
          )
          .join("")}
      </div>

      <div class="summary">
        <h2>Inspector Summary</h2>
        <p>${summaryText || "[Add your final comments here before exporting.]"}</p>
      </div>
    </body>
  </html>
  `;
}
