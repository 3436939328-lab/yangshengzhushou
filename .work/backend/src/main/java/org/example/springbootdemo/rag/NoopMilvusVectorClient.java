package org.example.springbootdemo.rag;

import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class NoopMilvusVectorClient implements MilvusVectorClient {

    @Override
    public List<KnowledgeHit> search(String queryText) {
        return List.of();
    }
}
