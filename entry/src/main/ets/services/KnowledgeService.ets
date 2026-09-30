import { AcupointGuide, FoodContraindication, HerbalRecipe } from '../model/WellnessModels';

const HERBAL_RECIPES: HerbalRecipe[] = [
  {
    name: '黄芪山药粥',
    ingredients: '黄芪、山药、粳米、红枣',
    effect: '补气健脾，缓解困乏、气短和胃口一般。',
    suitableFor: '气虚质'
  },
  {
    name: '莲子百合饮',
    ingredients: '莲子、百合、麦冬',
    effect: '养心安神，适合睡眠浅、夏季烦热。',
    suitableFor: '阴虚质'
  },
  {
    name: '薏米赤豆汤',
    ingredients: '薏米、赤小豆、陈皮',
    effect: '健脾祛湿，适合湿重困倦和舌苔厚腻。',
    suitableFor: '痰湿质'
  }
];

const FOOD_CONTRAINDICATIONS: FoodContraindication[] = [
  {
    food: '山楂',
    crowd: '孕期',
    property: '酸甘微温',
    warning: '孕期人群应谨慎大量食用，特殊情况先咨询医生。'
  },
  {
    food: '苦瓜',
    crowd: '脾胃虚寒',
    property: '寒凉',
    warning: '脾胃虚寒者不宜过量，避免加重腹泻或胃部不适。'
  },
  {
    food: '生姜',
    crowd: '阴虚火旺',
    property: '辛温',
    warning: '口干咽燥、潮热明显时谨慎频繁食用。'
  }
];

const ACUPOINTS: AcupointGuide[] = [
  {
    name: '神门',
    location: '腕横纹尺侧端凹陷处。',
    method: '适用于失眠、心烦，睡前轻揉 2 分钟。'
  },
  {
    name: '足三里',
    location: '外膝眼下约四横指，胫骨前嵴旁开一横指。',
    method: '适用于困乏、脾胃虚弱，双侧按揉 3 分钟。'
  },
  {
    name: '合谷',
    location: '手背第一、二掌骨之间，约第二掌骨桡侧中点。',
    method: '适用于头痛、肩颈紧张，孕期避免强刺激。'
  }
];

export function searchHerbalRecipes(keyword: string): HerbalRecipe[] {
  return HERBAL_RECIPES.filter((item: HerbalRecipe) => {
    return item.suitableFor.indexOf(keyword) >= 0 ||
      item.name.indexOf(keyword) >= 0 ||
      item.effect.indexOf(keyword) >= 0;
  });
}

export function searchFoodContraindications(keyword: string): FoodContraindication[] {
  return FOOD_CONTRAINDICATIONS.filter((item: FoodContraindication) => {
    return item.food.indexOf(keyword) >= 0 ||
      item.crowd.indexOf(keyword) >= 0 ||
      item.warning.indexOf(keyword) >= 0;
  });
}

export function searchAcupoints(keyword: string): AcupointGuide[] {
  return ACUPOINTS.filter((item: AcupointGuide) => {
    return item.name.indexOf(keyword) >= 0 ||
      item.method.indexOf(keyword) >= 0 ||
      item.location.indexOf(keyword) >= 0;
  });
}
