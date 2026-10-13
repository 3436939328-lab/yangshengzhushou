package org.example.springbootdemo.auth;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TokenStoreTest {

    @Test
    void signedTokenCanBeVerifiedByANewStoreWithTheSameSecret() {
        TokenStore firstStore = new TokenStore("unit-test-secret", 3600);
        String token = firstStore.createToken(42L);

        TokenStore restartedStore = new TokenStore("unit-test-secret", 3600);

        assertTrue(restartedStore.isValid(token));
        assertEquals(42L, restartedStore.getUserId(token));
    }

    @Test
    void signedTokenRejectsDifferentSecretAndMalformedTokens() {
        TokenStore firstStore = new TokenStore("unit-test-secret", 3600);
        String token = firstStore.createToken(42L);

        TokenStore otherStore = new TokenStore("other-secret", 3600);

        assertFalse(otherStore.isValid(token));
        assertFalse(firstStore.isValid("bad-token"));
    }
}
