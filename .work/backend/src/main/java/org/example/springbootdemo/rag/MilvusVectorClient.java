package org.example.springbootdemo.rag;

import java.util.List;

public interface MilvusVectorClient {

    List<KnowledgeHit> search(String queryText);
}
