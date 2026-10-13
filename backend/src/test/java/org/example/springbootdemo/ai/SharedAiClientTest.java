package org.example.springbootdemo.ai;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import org.example.springbootdemo.rag.LocalLlmClient;
import org.junit.jupiter.api.Test;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import static org.junit.jupiter.api.Assertions.*;
class SharedAiClientTest {
 @Test void chatAndSuggestionsUseSameModelAndActualStatus() throws Exception {
  var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
  var mapper=new ObjectMapper();var calls=new AtomicInteger();
  server.createContext("/chat/completions",exchange->{
   var payload=mapper.readTree(exchange.getRequestBody());assertEquals("deepseek-chat",payload.path("model").asText());
   String answer=calls.incrementAndGet()==1?"Real reply":"{\"summary\":\"Real suggestions\",\"suggestions\":[\"Walk\"],\"plans\":[]}";
   byte[] bytes=mapper.writeValueAsBytes(Map.of("choices",List.of(Map.of("message",Map.of("content",answer)))));
   exchange.sendResponseHeaders(200,bytes.length);exchange.getResponseBody().write(bytes);exchange.close();
  });server.start();
  try{
   var properties=new HealthQuestionAiProperties();properties.setBaseUrl("http://127.0.0.1:"+server.getAddress().getPort());properties.setApiKey("test-only");
   var status=new AiProviderStatus();var client=new OpenAiCompatibleHealthQuestionAiClient(properties,mapper,status);
   assertEquals("not_checked",status.snapshot(properties).get("status"));
   assertEquals("Real reply",client.generateAnswer(List.of(new AiChatMessage("user","question"))));
   assertEquals("Real suggestions",new LocalLlmClient(client,mapper).generate("suggest").summary());
   assertEquals(2,calls.get());assertEquals("available",status.snapshot(properties).get("status"));
  }finally{server.stop(0);}
 }
 @Test void rejectsProviderErrorsWithoutExposingResponseBody() throws Exception {
  var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
  server.createContext("/chat/completions",exchange->{byte[] bytes="private upstream detail".getBytes(StandardCharsets.UTF_8);exchange.sendResponseHeaders(401,bytes.length);exchange.getResponseBody().write(bytes);exchange.close();});server.start();
  try{
   var properties=new HealthQuestionAiProperties();properties.setBaseUrl("http://127.0.0.1:"+server.getAddress().getPort());properties.setApiKey("test-only");
   var status=new AiProviderStatus();var client=new OpenAiCompatibleHealthQuestionAiClient(properties,new ObjectMapper(),status);
   assertEquals("AI provider returned HTTP 401",assertThrows(IllegalStateException.class,()->client.generateAnswer(List.of())).getMessage());
   assertEquals("unavailable",status.snapshot(properties).get("status"));
  }finally{server.stop(0);}
 }
 @Test void missingKeyIsNotAvailable(){var properties=new HealthQuestionAiProperties();assertEquals("not_configured",new AiProviderStatus().snapshot(properties).get("status"));}
 @Test void invalidSuggestionJsonMarksSharedStatusUnavailable(){
  var properties=new HealthQuestionAiProperties();properties.setApiKey("test-only");
  var status=new AiProviderStatus();status.succeeded();
  HealthQuestionAiClient client=messages->"{}";
  var suggestions=new LocalLlmClient(client,new ObjectMapper(),status);
  assertThrows(IllegalStateException.class,()->suggestions.generate("suggest"));
  assertEquals("unavailable",status.snapshot(properties).get("status"));
 }
}
