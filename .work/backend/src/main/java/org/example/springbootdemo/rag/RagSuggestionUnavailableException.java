package org.example.springbootdemo.rag;

public class RagSuggestionUnavailableException extends RuntimeException {

    public RagSuggestionUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }

    public RagSuggestionUnavailableException(String message) {
        super(message);
    }
}
