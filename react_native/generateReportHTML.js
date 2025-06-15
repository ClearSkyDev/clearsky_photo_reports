export default function generateReportHTML(
  uploadedPhotos,
  roofQuestionnaire,
  summaryText = "",
  clientName = "",
  clientAddress = "",
  insuranceCarrier = "",
  claimNumber = "",
  perilType = "",
  inspectorName = "",
  reportId = "",
  weatherNotes = "",
  signatureData = "",
  inspectionDate = new Date().toLocaleDateString(),
  disclaimerText =
    "This report is for informational purposes only and is not a warranty."
) {
  const sectionOrder = [
    'Address',
    'Front Elevation',
    'Right Elevation',
    'Back Elevation',
    'Left Elevation',
    'Roof Edge',
    'Front Slope',
    'Right Slope',
    'Back Slope',
    'Left Slope',
    'Roof Accessories',
    'Roof Conditions',
  ];

  const groupedPhotos = {};
  // Preserve the original intake order for known sections
  sectionOrder.forEach((section) => {
    const photos = uploadedPhotos.filter((p) => p.sectionPrefix === section);
    if (photos.length) {
      groupedPhotos[section] = photos;
    }
  });
  // Append any sections not in the predefined order
  uploadedPhotos.forEach((p) => {
    if (!groupedPhotos[p.sectionPrefix]) {
      groupedPhotos[p.sectionPrefix] = [];
    }
    if (!groupedPhotos[p.sectionPrefix].includes(p)) {
      groupedPhotos[p.sectionPrefix].push(p);
    }
  });

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
      <img src="assets/images/clearsky_logo.png" alt="ClearSky Logo" style="max-width:200px;margin-bottom:20px;" />
      <h1>Roof Inspection Report</h1>
      <p><strong>Date:</strong> ${inspectionDate}</p>
      <p><strong>Client:</strong> ${clientName}</p>
      <p><strong>Address:</strong> ${clientAddress}</p>
      ${insuranceCarrier ? `<p><strong>Insurance Carrier:</strong> ${insuranceCarrier}</p>` : ''}
      <p><strong>Claim #:</strong> ${claimNumber}</p>
      <p><strong>Peril Type:</strong> ${perilType}</p>
      ${inspectorName ? `<p><strong>Inspector:</strong> ${inspectorName}</p>` : ''}
      ${reportId ? `<p><strong>Report ID:</strong> ${reportId}</p>` : ''}
      ${weatherNotes ? `<p><strong>Weather Notes:</strong> ${weatherNotes}</p>` : ''}

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
                <img src="${p.imageUri}" alt="Photo" style="width: 100%; aspect-ratio: 1 / 1; object-fit: cover; border-radius: 6px;" />
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

      ${signatureData ? `
        <div style="margin-top: 30px;">
          <h3>Inspector Signature:</h3>
          <img src="${signatureData}" alt="Signature" style="width: 300px; border: 1px solid #ccc;" />
        </div>
      ` : ''}
      <footer style="text-align:center;margin-top:40px;font-size:12px;color:#666;">${disclaimerText}</footer>
    </body>
  </html>
  `;
}
