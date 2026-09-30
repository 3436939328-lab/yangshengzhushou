package org.example.springbootdemo.service;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.ai.*;
import org.example.springbootdemo.rag.KnowledgeRetrievalService;
import org.junit.jupiter.api.Test;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class AssistantChatServiceTest {
 @Test void readsLegacyQuestionAnswerHistoryAsConversation() {
  HealthQuestionAiClient client = mock(HealthQuestionAiClient.class);
  KnowledgeRetrievalService retrieval = mock(KnowledgeRetrievalService.class);
  when(client.generateAnswer(anyList())).thenAnswer(invocation -> {
   List<AiChatMessage> messages=invocation.getArgument(0);
   assertTrue(messages.contains(new AiChatMessage("user","old question")));
   assertTrue(messages.contains(new AiChatMessage("assistant","old answer")));
   return "answer";
  });
  var service=new AssistantChatService(client,retrieval,new HealthQuestionAiProperties(),new ObjectMapper());
  service.chat(new AssistantChatRequest("question",Map.of(),Map.of(),List.of(Map.of("question","old question","answer","old answer"))),List.of());
 }
 @Test void forwardsContextAndDoesNotHideFailure() {
  HealthQuestionAiClient client = mock(HealthQuestionAiClient.class);
  KnowledgeRetrievalService retrieval = mock(KnowledgeRetrievalService.class);
  when(retrieval.retrieve(any())).thenReturn(List.of());
  AssistantChatService service = new AssistantChatService(client, retrieval, new HealthQuestionAiProperties(), new ObjectMapper());
  when(client.generateAnswer(anyList())).thenAnswer(invocation -> {
   List<AiChatMessage> messages = invocation.getArgument(0);
   assertTrue(messages.toString().contains("Shanghai"));
   assertTrue(messages.toString().contains("prior answer"));
   return "real answer";
  });
  var request = new AssistantChatRequest("question", Map.of("constitution", "test"), Map.of("city", "Shanghai"), List.of(Map.of("role", "assistant", "content", "prior answer")));
  assertEquals("real answer", service.chat(request, List.of()).reply());
  doThrow(new IllegalStateException("provider unavailable")).when(client).generateAnswer(anyList());
  assertThrows(IllegalStateException.class, () -> service.chat(request, List.of()));
 }
}
