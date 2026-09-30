import { AcupointGuide, HerbalRecipe, RecommendationPlan } from '../model/WellnessModels';

const QI_DEFICIENCY_RECIPE: HerbalRecipe = {
  name: '黄芪山药粥',
  ingredients: '黄芪、山药、粳米、红枣',
  effect: '补气健脾，适合困乏、气短、胃口一般的人群。',
  suitableFor: '气虚质'
};

const DEFAULT_RECIPE: HerbalRecipe = {
  name: '莲子百合饮',
  ingredients: '莲子、百合、麦冬、少量冰糖',
  effect: '养心安神，适合夏季烦热、睡眠欠佳时饮用。',
  suitableFor: '平和质'
};

const ZUSANLI: AcupointGuide = {
  name: '足三里',
  location: '外膝眼下约四横指，胫骨前嵴旁开一横指。',
  method: '双侧按揉 3 分钟，以酸胀温热为度。'
};

const SHENMEN: AcupointGuide = {
  name: '神门',
  location: '腕横纹尺侧端凹陷处。',
  method: '睡前轻揉 2 分钟，配合缓慢呼吸。'
};

export function recommendByProfile(constitution: string, symptom: string): RecommendationPlan {
  const recipe = constitution === '气虚质' || symptom.indexOf('困乏') >= 0 || symptom.indexOf('困倦') >= 0 ? QI_DEFICIENCY_RECIPE : DEFAULT_RECIPE;
  const acupoint = symptom.indexOf('失眠') >= 0 || symptom.indexOf('睡') >= 0 ? SHENMEN : ZUSANLI;

  return {
    recipe,
    acupoint,
    warning: '以上建议用于日常养生参考，不替代诊疗；明显不适请及时就医。'
  };
}
