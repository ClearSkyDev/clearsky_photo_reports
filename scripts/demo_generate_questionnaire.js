const { buildRoofQuestionnaire } = require('../react_native/roofQuestionnaire');

const uploadedPhotos = [
  {
    id: '1',
    sectionPrefix: 'Front Elevation',
    userLabel: 'Front Elevation – Downspout – Possible Hail Damage',
    aiSuggestedLabel: 'Front Elevation – Downspout – Possible Hail Damage',
    approved: true,
  },
  {
    id: '2',
    sectionPrefix: 'Front Slope',
    userLabel: 'Front Slope – Shingle Crease – Wind Lift',
    aiSuggestedLabel: 'Front Slope – Shingle Crease – Wind Lift',
    approved: true,
  },
  {
    id: '3',
    sectionPrefix: 'Accessories & Conditions',
    userLabel: 'Satellite Dish – Improper Mount',
    aiSuggestedLabel: 'Satellite Dish – Improper Mount',
    approved: true,
  },
];

const questionnaire = buildRoofQuestionnaire(uploadedPhotos);
console.log(JSON.stringify(questionnaire, null, 2));
