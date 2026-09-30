import {
  QuestionnaireAnswer,
  QuestionnaireOption,
  QuestionnaireQuestion,
  QuestionnaireRecord
} from '../model/ProfileModels';
import { ConstitutionResult } from '../model/WellnessModels';
import { calculateConstitution } from '../utils/ConstitutionUtil';

const OPTIONS: QuestionnaireOption[] = [
  { label: '很少', score: 0 },
  { label: '偶尔', score: 1 },
  { label: '有时', score: 2 },
  { label: '经常', score: 3 }
];

const QUESTIONS: QuestionnaireQuestion[] = [
  { id: 'energy', group: '精神体力', title: '你是否容易精神不足、疲乏无力？', options: OPTIONS },
  { id: 'breath', group: '精神体力', title: '你是否容易气短、说话声音偏低？', options: OPTIONS },
  { id: 'sweat', group: '日常表现', title: '你是否活动后容易出汗？', options: OPTIONS },
  { id: 'appetite', group: '脾胃状态', title: '你是否胃口一般或饭后容易困倦？', options: OPTIONS },
  { id: 'sleep', group: '睡眠恢复', title: '你是否睡醒后仍觉得恢复不够？', options: OPTIONS },
  { id: 'cold', group: '寒热感受', title: '你是否比别人更怕冷或手脚偏凉？', options: OPTIONS }
];

export function getConstitutionQuestions(): QuestionnaireQuestion[] {
  return QUESTIONS;
}

export function scoreConstitutionAnswers(answers: QuestionnaireAnswer[]): ConstitutionResult {
  const scores: number[] = [];
  for (let index = 0; index < answers.length; index++) {
    scores.push(answers[index].score);
  }
  return calculateConstitution(scores);
}

export function buildQuestionnaireRecord(answers: QuestionnaireAnswer[], submittedAt: string): QuestionnaireRecord {
  const constitution = scoreConstitutionAnswers(answers);
  return {
    submittedAt,
    answers,
    totalScore: constitution.score,
    constitution,
    suggestion: constitution.suggestion
  };
}
