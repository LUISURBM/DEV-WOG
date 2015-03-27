/* Formatted on 2015/03/27 15:19 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FUNCTION APLIGAS.COM_FN_RTV_APORTE (
   FN_AD_USER_SESSION_ID   IN       NUMBER,
   FN_AD_CLIENT_ID         IN       NUMBER,
   FN_AD_ORG_ID            IN       NUMBER,
   V_IND_APORTE            IN       NUMBER,
   V_IND_APORTE_ANT        IN       NUMBER,
   V_TIENE_APORTES         OUT      CHAR,
   MSG_ERROR               OUT      VARCHAR2
)
   RETURN CHAR
IS
   V_VALOR   NUMBER (1, 0) DEFAULT 0;
BEGIN
   IF (V_IND_APORTE = 'N' AND V_IND_APORTE_ANT = 'N')
   THEN
      V_TIENE_APORTES := 'N';
   END IF;

   IF (V_IND_APORTE = 'Y' AND V_IND_APORTE_ANT = 'N')
   THEN
      V_TIENE_APORTES := 'Y';
   END IF;

   IF (V_IND_APORTE = 'N' AND V_IND_APORTE_ANT = 'Y')
   THEN
      V_TIENE_APORTES := 'H';
   END IF;

   IF (V_IND_APORTE = 'Y' AND V_IND_APORTE_ANT = 'Y')
   THEN
      V_TIENE_APORTES := 'A';
   END IF;

   RETURN V_TIENE_APORTES;
END;
/