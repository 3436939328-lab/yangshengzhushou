import { ConstitutionResult } from '../model/WellnessModels';

export function calculateConstitution(scores: number[]): ConstitutionResult {
  if (scores.length === 0) {
    return {
      name: '平和质',
      score: 0,
      suggestion: '保持规律作息，饮食有节，继续维持稳定状态。'
    };
  }

  let total = 0;
  for (let index = 0; index < scores.length; index++) {
    total += scores[index];
  }

  if (total >= 8) {
    return {
      name: '气虚质',
      score: total,
      suggestion: '优先补气健脾，选择温和运动，避免过度劳累。'
    };
  }

  return {
    name: '平和质',
    score: total,
    suggestion: '保持规律作息，饮食有节，继续维持稳定状态。'
  };
}
