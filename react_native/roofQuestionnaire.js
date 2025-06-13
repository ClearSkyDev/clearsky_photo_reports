// Utility to pre-fill a roof questionnaire based on confirmed photo labels
// Usage: import { buildRoofQuestionnaire } from './roofQuestionnaire';
//        const questionnaire = buildRoofQuestionnaire(uploadedPhotos);

function buildRoofQuestionnaire(uploadedPhotos) {
  const roofQuestionnaire = {
    elevations: {
      front: [],
      right: [],
      back: [],
      left: []
    },
    slopes: {
      front: [],
      right: [],
      back: [],
      left: []
    },
    accessories: [],
    generalConditions: [],
    damageSummary: []
  };

  uploadedPhotos.forEach(photo => {
    if (!photo.approved || !photo.userLabel) return;

    const label = photo.userLabel.toLowerCase();
    const prefix = photo.sectionPrefix.toLowerCase();

    // Elevation damage
    if (prefix.includes('elevation')) {
      const key = prefix.includes('front')
        ? 'front'
        : prefix.includes('right')
        ? 'right'
        : prefix.includes('back')
        ? 'back'
        : prefix.includes('left')
        ? 'left'
        : null;
      if (key) {
        roofQuestionnaire.elevations[key].push(label);
      }
    }

    // Roof slope damage
    if (prefix.includes('slope')) {
      const key = prefix.includes('front')
        ? 'front'
        : prefix.includes('right')
        ? 'right'
        : prefix.includes('back')
        ? 'back'
        : prefix.includes('left')
        ? 'left'
        : null;
      if (key) {
        roofQuestionnaire.slopes[key].push(label);
      }
    }

    // Accessories
    if (prefix.includes('accessories') || label.includes('satellite') || label.includes('skylight')) {
      roofQuestionnaire.accessories.push(label);
    }

    // General conditions
    if (prefix.includes('rear yard') || prefix.includes('address')) {
      roofQuestionnaire.generalConditions.push(label);
    }

    // Damage summary
    if (label.includes('damage') || label.includes('crack') || label.includes('missing') || label.includes('lift')) {
      roofQuestionnaire.damageSummary.push(label);
    }
  });

  return roofQuestionnaire;
}

module.exports = { buildRoofQuestionnaire };
