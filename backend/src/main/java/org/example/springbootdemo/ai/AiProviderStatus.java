package org.example.springbootdemo.ai;
import org.springframework.stereotype.Component;
import java.time.Instant;
import java.util.*;
@Component
public class AiProviderStatus {
 private volatile Observation observation=new Observation("not_checked",null,"No model request has completed yet");
 private record Observation(String status,String checkedAt,String message){}
 public void succeeded(){observation=new Observation("available",Instant.now().toString(),"Last model request succeeded");}
 public void failed(String message){observation=new Observation("unavailable",Instant.now().toString(),message);}
 public Map<String,Object> snapshot(HealthQuestionAiProperties properties){
  boolean configured=properties.getBaseUrl()!=null&&!properties.getBaseUrl().isBlank()&&properties.getModel()!=null&&!properties.getModel().isBlank()&&("local".equals(properties.getProvider())||(properties.getApiKey()!=null&&!properties.getApiKey().isBlank()));
  Observation value=observation;Map<String,Object> result=new LinkedHashMap<>();
  result.put("provider",properties.getProvider());result.put("model",properties.getModel());result.put("configured",configured);result.put("status",configured?value.status():"not_configured");result.put("lastCheckedAt",value.checkedAt());result.put("message",configured?value.message():"AI credentials or configuration are missing");return result;
 }
}
