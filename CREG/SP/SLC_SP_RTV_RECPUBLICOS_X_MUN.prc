
CREATE OR REPLACE PROCEDURE APLIGAS.SLC_SP_RTV_RECPUBLICOS_X_MUN (
   PD_AD_USER_SESSION_ID       IN       NUMBER,
   PD_AD_CLIENT_ID             IN       NUMBER,
   PD_AD_ORG_ID                IN       NUMBER,
   P_SLC_TARIFARIA_ID          IN       NUMBER,
   P_C_REGION_ID               IN       NUMBER,
   P_C_CITY_ID                 IN       NUMBER,
   P_C_SECTOR_ID               IN       NUMBER,
   P_SLC_MERCADO_ESPECIAL_ID   IN       NUMBER,
   P_INDICADOR                 OUT      CHAR,
   MSG_ERROR                   OUT      VARCHAR2,
   ERROR_SOURCE                OUT      VARCHAR2
)
IS
   V_SLC_RECUR_PUBLICO_ID      NUMBER (10, 0);
   V_SLC_CONT_REG              NUMBER (10, 0);
   V_SLC_MERCADO_ESPECIAL_ID   NUMBER (10, 0);
   V_COUNT_RPUBLICO_MUN        NUMBER;
   SPCALL_ERROR                EXCEPTION;
   SPLOGIC_ERROR               EXCEPTION;
   VD_AD_CLIENT_ID             NUMBER (10, 0);
   VD_AD_ORG_ID                NUMBER (10, 0);
   VD_AD_USER_ID               NUMBER (10, 0);
BEGIN
   VD_AD_CLIENT_ID :=
      APLIGAS.ADM_FN_RTV_CLIENT_DEFAULT (PD_AD_USER_SESSION_ID,
                                         PD_AD_CLIENT_ID,
                                         PD_AD_ORG_ID
                                        );
   VD_AD_ORG_ID :=
      APLIGAS.ADM_FN_RTV_ORG_DEFAULT (PD_AD_USER_SESSION_ID,
                                      PD_AD_CLIENT_ID,
                                      PD_AD_ORG_ID
                                     );
   VD_AD_USER_ID :=
      APLIGAS.ADM_FN_RTV_USER_DEFAULT (PD_AD_USER_SESSION_ID,
                                       PD_AD_CLIENT_ID,
                                       PD_AD_ORG_ID
                                      );

   BEGIN
      SELECT SLC_RECUR_PUBLICO_ID
        INTO V_SLC_RECUR_PUBLICO_ID
        FROM APLIGAS.SLC_RECUR_PUBLICO
       WHERE SLC_TARIFARIA_ID = P_SLC_TARIFARIA_ID AND ESTADO = 'A';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_SLC_RECUR_PUBLICO_ID := NULL;
   END;

   IF (V_SLC_RECUR_PUBLICO_ID IS NULL)
   THEN
      P_INDICADOR := 'N';
   ELSE
      BEGIN
         SELECT COUNT (1)
           INTO V_SLC_CONT_REG
           FROM APLIGAS.SLC_RPUBLICO_GEN
          WHERE SLC_RECUR_PUBLICO_ID = V_SLC_RECUR_PUBLICO_ID AND ESTADO = 'A';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_SLC_CONT_REG := 0;
      END;

      IF (V_SLC_CONT_REG > 0)
      THEN
         P_INDICADOR := 'Y';
      ELSE
         IF (P_SLC_MERCADO_ESPECIAL_ID IS NOT NULL)
         THEN
            V_SLC_MERCADO_ESPECIAL_ID := P_SLC_MERCADO_ESPECIAL_ID;
         ELSE
            IF (P_C_SECTOR_ID IS NOT NULL)
            THEN
               BEGIN
                  SELECT SLC_MERCADO_ESPECIAL_ID
                    INTO V_SLC_MERCADO_ESPECIAL_ID
                    FROM SLC_MERCADO_ESPECIAL
                   WHERE SLC_TARIFARIA_ID = P_SLC_TARIFARIA_ID
                     AND C_REGION_ID = P_C_REGION_ID
                     AND C_CITY_ID = P_C_CITY_ID
                     AND C_SECTOR_ID = P_C_SECTOR_ID
                     AND ESTADO = 'A';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     V_SLC_MERCADO_ESPECIAL_ID := NULL;
               END;
            END IF;

            IF (P_C_SECTOR_ID IS NULL)
            THEN
               V_SLC_MERCADO_ESPECIAL_ID := NULL;
            END IF;

            BEGIN
               SELECT COUNT (1)
                 INTO V_COUNT_RPUBLICO_MUN
                 FROM APLIGAS.SLC_RPUBLICO_MUN
                WHERE SLC_RECUR_PUBLICO_ID = V_SLC_RECUR_PUBLICO_ID
                  AND C_REGION_ID = P_C_REGION_ID
                  AND C_CITY_ID = P_C_CITY_ID
                  AND ((       (P_C_SECTOR_ID IS NOT NULL)
                           AND ((C_SECTOR_ID = P_C_SECTOR_ID))
                        OR ((P_C_SECTOR_ID IS NULL) AND (C_SECTOR_ID IS NULL)
                           )
                       )
                      )
                  AND (   (    (V_SLC_MERCADO_ESPECIAL_ID IS NOT NULL)
                           AND (SLC_MERCADO_ESPECIAL_ID =
                                                     V_SLC_MERCADO_ESPECIAL_ID
                               )
                          )
                       OR (    (V_SLC_MERCADO_ESPECIAL_ID IS NULL)
                           AND (SLC_MERCADO_ESPECIAL_ID IS NULL)
                          )
                      )
                  AND ESTADO = 'A';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_COUNT_RPUBLICO_MUN := NULL;
            END;

            IF (V_COUNT_RPUBLICO_MUN > 0)
            THEN
               P_INDICADOR := 'Y';
            ELSE
               P_INDICADOR := 'N';
            END IF;
         END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN SPLOGIC_ERROR
   THEN
      ERROR_SOURCE := ERROR_SOURCE || ' - SLC_SP_RTV_RECPUBLICOS_X_MUN';
      ROLLBACK;
   WHEN SPCALL_ERROR
   THEN
      ERROR_SOURCE := ERROR_SOURCE || ' - SLC_SP_RTV_RECPUBLICOS_X_MUN';
      ROLLBACK;
   WHEN OTHERS
   THEN
      ERROR_SOURCE := SQLERRM || ' - SLC_SP_RTV_RECPUBLICOS_X_MUN';
      MSG_ERROR := 'TRG-@4302@<BR>';
      ROLLBACK;
END;
/