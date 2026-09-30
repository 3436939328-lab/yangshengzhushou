package org.example.springbootdemo.rewards;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
class RewardsServiceTest {
 RewardsService service;
 JdbcTemplate jdbc;
 DataSourceTransactionManager manager;
 Clock clock=Clock.fixed(Instant.parse("2026-09-08T16:01:00Z"),ZoneOffset.UTC);
 @BeforeEach void setup(){
  var ds=new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=MySQL;DB_CLOSE_DELAY=-1", "sa", "");
  jdbc=new JdbcTemplate(ds);
  manager=new DataSourceTransactionManager(ds);
  new RewardsSchemaInitializer(jdbc).run();
  service=new RewardsService(jdbc,manager,new ObjectMapper(),clock);
 }
 @Test void chinaDayCheckInIsIdempotent(){
  assertEquals(10,service.checkIn(1L).get("balance"));
  assertEquals(10,service.checkIn(1L).get("balance"));
  assertEquals(1,service.ledger(1L).size());
  assertEquals("2026-09-09",service.ledger(1L).get(0).get("reference"));
 }
 @Test void reserveRefundAndRetryDoNotDebit(){
  service.checkIn(1L); service.reserveChat(1L,"req1","hash");
  assertEquals(9,service.account(1L).get("available"));
  service.failChat(1L,"req1","Unavailable");
  assertEquals(10,service.account(1L).get("available"));
  assertEquals("FAILED",service.chatResult(1L,"req1").get("status"));
 }
 @Test void settlementIsIdempotentAndReplyRecoverable(){
  service.checkIn(1L);service.reserveChat(1L,"req1","hash");
  var reply=new org.example.springbootdemo.ai.AssistantChatReply("answer","deepseek","normal",List.of(),List.of(),"");
  service.completeChat(1L,"req1",reply);service.completeChat(1L,"req1",reply);
  assertEquals(9,service.account(1L).get("balance"));
  assertEquals("SUCCEEDED",service.chatResult(1L,"req1").get("status"));
  assertEquals(reply,service.chatResult(1L,"req1").get("reply"));
 }
 @Test void concurrentReservationsCannotOverspend() throws Exception {
  service.checkIn(1L);var pool=Executors.newFixedThreadPool(12);
  try {var tasks=new ArrayList<Callable<Boolean>>();
   for(int i=0;i<20;i++){String id="r"+i;tasks.add(()->{try{service.reserveChat(1L,id,"hash");return true;}catch(RewardsException e){return false;}});}
   long successes=pool.invokeAll(tasks).stream().filter(f->{try{return f.get();}catch(Exception e){throw new RuntimeException(e);}}).count();
   assertEquals(10,successes);assertEquals(0,service.account(1L).get("available"));
  }finally{pool.shutdownNow();}
 }
 @Test void stockAndDebitAreAtomicAndOrderRetryIsIdempotent(){
  service.checkIn(1L);service.checkIn(2L);
  var product=service.saveProduct(null,new RewardsService.ProductInput("Cup","", "", 5,1,true));
  long id=((Number)product.get("id")).longValue();
  var input=new RewardsService.OrderInput("order1",id,"Name","13800000000","Shanghai address",true);
  var order=service.order(1L,input);
  assertEquals(order.get("id"),service.order(1L,input).get("id"));
  assertThrows(RewardsException.class,()->service.order(2L,new RewardsService.OrderInput("order2",id,"Name","13800000000","Shanghai address",true)));
  assertEquals(5,service.account(1L).get("balance"));assertEquals(10,service.account(2L).get("balance"));
  assertEquals(0,service.orders(2L).size());
 }
 @Test void crashedRequestExpiresAndReturnsReservedPoints(){
  service.checkIn(1L);service.reserveChat(1L,"crashed","hash");
  var later=new RewardsService(jdbc,manager,new ObjectMapper(),Clock.offset(clock,Duration.ofMinutes(4)));
  assertEquals("FAILED",later.chatResult(1L,"crashed").get("status"));
  assertEquals(10,later.account(1L).get("available"));
  assertThrows(RewardsException.class,()->later.completeChat(1L,"crashed",null));
 }
 @Test void concurrentOrdersCannotSellLastItemTwice() throws Exception {
  service.checkIn(1L);service.checkIn(2L);
  long id=((Number)service.saveProduct(null,new RewardsService.ProductInput("Cup","","",5,1,true)).get("id")).longValue();
  var pool=Executors.newFixedThreadPool(2);
  try {
   var results=pool.invokeAll(List.<Callable<Boolean>>of(
    ()->{try{service.order(1L,new RewardsService.OrderInput("a",id,"N","13800000000","Address",true));return true;}catch(RewardsException e){return false;}},
    ()->{try{service.order(2L,new RewardsService.OrderInput("b",id,"N","13800000000","Address",true));return true;}catch(RewardsException e){return false;}}
   ));
   assertNotEquals(results.get(0).get(),results.get(1).get());
   assertEquals(15,((Number)service.account(1L).get("balance")).intValue()+((Number)service.account(2L).get("balance")).intValue());
  }finally{pool.shutdownNow();}
 }
 @Test void insufficientFundsDoNotReduceStock(){
  long id=((Number)service.saveProduct(null,new RewardsService.ProductInput("Cup","","",5,1,true)).get("id")).longValue();
  assertThrows(RewardsException.class,()->service.order(1L,new RewardsService.OrderInput("a",id,"N","13800000000","Address",true)));
  assertEquals(1,service.products(false).get(0).get("stock"));
 }
}
