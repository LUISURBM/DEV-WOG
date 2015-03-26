CREATE OR REPLACE PROCEDURE apligas.gst_sp_rtv_recpublicos_x_mun (
   pd_ad_user_session_id       IN       NUMBER,
   pd_ad_client_id             IN       NUMBER,
   pd_ad_org_id                IN       NUMBER,
   p_gst_tarifaria_id          IN       NUMBER,
   p_c_region_id               IN       NUMBER,
   p_c_city_id                 IN       NUMBER,
   p_c_sector_id               IN       NUMBER,
   p_gst_mercado_especial_id   IN       NUMBER,
   p_indicador                 OUT      CHAR,
   msg_error                   OUT      VARCHAR2,
   error_source                OUT      VARCHAR2
)
IS
   v_gst_recur_publico_id      NUMBER (10, 0);
   v_gst_cont_reg              NUMBER (10, 0);
   v_gst_mercado_especial_id   NUMBER (10, 0);
   v_count_rpublico_mun        NUMBER;
   spcall_error                EXCEPTION;
   splogic_error               EXCEPTION;
   vd_ad_client_id             NUMBER (10, 0);
   vd_ad_org_id                NUMBER (10, 0);
   vd_ad_user_id               NUMBER (10, 0);
BEGIN
   vd_ad_client_id :=
      apligas.adm_fn_rtv_client_default (pd_ad_user_session_id,
                                         pd_ad_client_id,
                                         pd_ad_org_id
                                        );
   vd_ad_org_id :=
      apligas.adm_fn_rtv_org_default (pd_ad_user_session_id,
                                      pd_ad_client_id,
                                      pd_ad_org_id
                                     );
   vd_ad_user_id :=
      apligas.adm_fn_rtv_user_default (pd_ad_user_session_id,
                                       pd_ad_client_id,
                                       pd_ad_org_id
                                      );

   BEGIN
      SELECT gst_recur_publico_id
        INTO v_gst_recur_publico_id
        FROM apligas.gst_recur_publico
       WHERE gst_tarifaria_id = p_gst_tarifaria_id AND estado = 'A';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_gst_recur_publico_id := NULL;
   END;

   IF (v_gst_recur_publico_id IS NULL)
   THEN
      p_indicador := 'N';
   ELSE
      BEGIN
         SELECT COUNT (1)
           INTO v_gst_cont_reg
           FROM apligas.gst_rpublico_gen
          WHERE gst_recur_publico_id = v_gst_recur_publico_id AND estado = 'A';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_gst_cont_reg := 0;
      END;

      IF (v_gst_cont_reg > 0)
      THEN
         p_indicador := 'Y';
      ELSE
         IF (p_gst_mercado_especial_id IS NOT NULL)
         THEN
            v_gst_mercado_especial_id := p_gst_mercado_especial_id;
         ELSE
            IF (p_c_sector_id IS NOT NULL)
            THEN
               BEGIN
                  SELECT gst_mercado_especial_id
                    INTO v_gst_mercado_especial_id
                    FROM gst_mercado_especial
                   WHERE gst_tarifaria_id = p_gst_tarifaria_id
                     AND c_region_id = p_c_region_id
                     AND c_city_id = p_c_city_id
                     AND c_sector_id = p_c_sector_id
                     AND estado = 'A';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_gst_mercado_especial_id := NULL;
               END;

               IF (p_c_sector_id IS NULL)
               THEN
                  v_gst_mercado_especial_id := NULL;
               END IF;

               BEGIN
                  SELECT COUNT (1)
                    INTO v_count_rpublico_mun
                    FROM apligas.gst_rpublico_mun
                   WHERE     gst_recur_publico_id = v_gst_recur_publico_id
                         AND c_region_id = p_c_region_id
                         AND c_city_id = p_c_city_id
                         AND (p_c_sector_id IS NOT NULL)
                         AND (   (c_sector_id = p_c_sector_id)
                              OR (    (p_c_sector_id IS NULL)
                                  AND (c_sector_id IS NULL)
                                 )
                             )
                         AND (    (v_gst_mercado_especial_id IS NOT NULL)
                              AND (gst_mercado_especial_id =
                                                     v_gst_mercado_especial_id
                                  )
                             )
                      OR (    (v_gst_mercado_especial_id IS NULL)
                          AND (gst_mercado_especial_id IS NULL)
                         );
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_count_rpublico_mun := NULL;
               END;

               IF (v_count_rpublico_mun > 0)
               THEN
                  p_indicador := 'Y';
               END IF;
            END IF;
         END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN splogic_error
   THEN
      error_source := error_source || ' - GST_SP_RTV_RECPUBLICOS_X_MUN';
      ROLLBACK;
   WHEN spcall_error
   THEN
      error_source := error_source || ' - GST_SP_RTV_RECPUBLICOS_X_MUN';
      ROLLBACK;
   WHEN OTHERS
   THEN
      error_source := SQLERRM || ' - GST_SP_RTV_RECPUBLICOS_X_MUN';
      msg_error := 'TRG-@4302@<br>';
      ROLLBACK;
END;
/