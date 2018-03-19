create or replace FUNCTION AJAX_DIPA_GET_TABLE (
ID IN NUMBER,
KODE_KEG IN VARCHAR2,
THN IN NUMBER,
KEYIN IN VARCHAR2,
PARAMS IN VARCHAR2
) RETURN STRTABLE_TYPE_TABLE
PIPELINED
AS
strTable clob;
kd_kegiatan number;
kd_output number;
kd_suboutput varchar2(100);
kd_komponen number;
kd_sub_komponen number;
kd_jns_belanja number;
id_rab number;
-- SECTION OUTPUT
CURSOR C_OUTPUT ( ID_KEGIATAN IN NUMBER,THN IN NUMBER) IS
        SELECT 
        T_BASELINE_OUTPUT_KEGIATAN.ID,
            T_RAB_HEADER.TAHUN_ANGGARAN,
            (T_KEGIATAN_BASELINE.KODE||'.'||T_BASELINE_OUTPUT_KEGIATAN.KODE||'.'||T_RAB_HEADER.SUB_OUTPUT) AS KODE, 
            T_BASELINE_OUTPUT_KEGIATAN.NAMA,
            SUM (NVL(T_RAB_COA.JUMLAH_COA,0))AS PAGU, 
            sum(NVL(T_RAB_COA.BLOKIR,0))as BLOKIR,
            T_RAB_HEADER.KEGIATAN,
            T_RAB_HEADER.OUTPUT_KEGIATAN,
            T_RAB_HEADER.SUB_OUTPUT
            FROM T_RAB_HEADER 
            INNER JOIN T_BASELINE_OUTPUT_KEGIATAN ON T_RAB_HEADER.OUTPUT_KEGIATAN = T_BASELINE_OUTPUT_KEGIATAN.ID 
            INNER JOIN T_KEGIATAN_BASELINE ON T_RAB_HEADER.KEGIATAN = T_KEGIATAN_BASELINE.ID
            INNER JOIN T_RAB_COA ON T_RAB_HEADER.ID = T_RAB_COA.ID_RAB
             WHERE T_RAB_HEADER.TAHUN_ANGGARAN = THN
                AND T_RAB_HEADER.JENIS = 3 
                AND T_RAB_HEADER.LAST = 1 
                AND T_RAB_HEADER.STATUS = 9
                AND T_RAB_HEADER.KEGIATAN = ID_KEGIATAN
            GROUP BY  T_BASELINE_OUTPUT_KEGIATAN.ID,T_RAB_HEADER.TAHUN_ANGGARAN,
                        (T_KEGIATAN_BASELINE.KODE||'.'||T_BASELINE_OUTPUT_KEGIATAN.KODE||'.'||T_RAB_HEADER.SUB_OUTPUT), 
                        T_BASELINE_OUTPUT_KEGIATAN.NAMA,
                        T_RAB_HEADER.KEGIATAN,
            T_RAB_HEADER.OUTPUT_KEGIATAN,
            T_RAB_HEADER.SUB_OUTPUT;
g C_OUTPUT%ROWTYPE;

cursor cur_komponen (vID in number, thn in number, idkegiatan in number, idoutput IN number, idsubouput IN VARCHAR2) is
    SELECT  T_KOMPONEN_KEGIATAN.ID,
            T_RAB_HEADER.TAHUN_ANGGARAN,
            (T_KEGIATAN_BASELINE.KODE||'.'||T_BASELINE_OUTPUT_KEGIATAN.KODE||'.'||T_RAB_HEADER.SUB_OUTPUT||'.'||T_KOMPONEN_KEGIATAN.KODE) AS KODE, 
            T_KOMPONEN_KEGIATAN.NAMA,
            T_KEGIATAN_BASELINE.ID AS ID_KEGIATAN,
            T_RAB_HEADER.OUTPUT_KEGIATAN,
            T_RAB_HEADER.SUB_OUTPUT,
            SUM (NVL(T_RAB_COA.JUMLAH_COA,0))AS PAGU, 
            sum(NVL(T_RAB_COA.BLOKIR,0))as BLOKIR
            FROM T_RAB_HEADER 
            INNER JOIN T_KOMPONEN_KEGIATAN ON T_RAB_HEADER.KOMPONEN = T_KOMPONEN_KEGIATAN.ID
            INNER JOIN T_BASELINE_OUTPUT_KEGIATAN ON T_RAB_HEADER.OUTPUT_KEGIATAN = T_BASELINE_OUTPUT_KEGIATAN.ID 
            INNER JOIN T_KEGIATAN_BASELINE ON T_RAB_HEADER.KEGIATAN = T_KEGIATAN_BASELINE.ID
            INNER JOIN T_RAB_COA ON T_RAB_HEADER.ID = T_RAB_COA.ID_RAB
             WHERE T_RAB_HEADER.TAHUN_ANGGARAN = thn
                AND T_RAB_HEADER.JENIS = 3 
                AND T_RAB_HEADER.LAST = 1 
                AND T_RAB_HEADER.STATUS = 9
                AND T_RAB_HEADER.KEGIATAN = idkegiatan
                AND T_RAB_HEADER.OUTPUT_KEGIATAN = idoutput
                AND T_RAB_HEADER.SUB_OUTPUT = idsubouput
            GROUP BY  T_KOMPONEN_KEGIATAN.ID,
                     T_RAB_HEADER.TAHUN_ANGGARAN,
                    (T_KEGIATAN_BASELINE.KODE||'.'||T_BASELINE_OUTPUT_KEGIATAN.KODE||'.'||T_RAB_HEADER.SUB_OUTPUT||'.'||T_KOMPONEN_KEGIATAN.KODE),
                    T_KOMPONEN_KEGIATAN.KODE , 
                    T_KOMPONEN_KEGIATAN.NAMA,
                    T_KEGIATAN_BASELINE.ID,
                    T_RAB_HEADER.OUTPUT_KEGIATAN,
                    T_RAB_HEADER.SUB_OUTPUT;
h cur_komponen%rowtype;

CURSOR C_SUB_KOMPONEN (thn in number, idkegiatan in number, idoutput IN number, idsubouput IN VARCHAR2, idkomponen in number) IS
   SELECT  T_RAB_SUB_KOMPONEN.ID,T_RAB_COA.ID_RAB,
            T_RAB_HEADER.TAHUN_ANGGARAN,
            T_RAB_SUB_KOMPONEN.KODE AS KODE, 
            T_RAB_SUB_KOMPONEN.URAIAN AS NAMA,
            SUM (NVL(T_RAB_COA.JUMLAH_COA,0))AS PAGU, 
            sum(NVL(T_RAB_COA.BLOKIR,0))as BLOKIR
            FROM T_RAB_HEADER 
            INNER JOIN T_RAB_SUB_KOMPONEN ON T_RAB_HEADER.ID = T_RAB_SUB_KOMPONEN.ID_RAB
            INNER JOIN T_KOMPONEN_KEGIATAN ON T_RAB_HEADER.KOMPONEN = T_KOMPONEN_KEGIATAN.ID
            INNER JOIN T_BASELINE_OUTPUT_KEGIATAN ON T_RAB_HEADER.OUTPUT_KEGIATAN = T_BASELINE_OUTPUT_KEGIATAN.ID 
            INNER JOIN T_KEGIATAN_BASELINE ON T_RAB_HEADER.KEGIATAN = T_KEGIATAN_BASELINE.ID
            INNER JOIN T_RAB_COA ON T_RAB_HEADER.ID = T_RAB_COA.ID_RAB AND T_RAB_SUB_KOMPONEN.ID = T_RAB_COA.ID_SUB
             WHERE T_RAB_HEADER.TAHUN_ANGGARAN = thn
                AND T_RAB_HEADER.JENIS = 3 
                AND T_RAB_HEADER.LAST = 1 
                AND T_RAB_HEADER.STATUS = 9
                AND T_RAB_HEADER.KEGIATAN = idkegiatan
                AND T_RAB_HEADER.OUTPUT_KEGIATAN = idoutput
                AND T_RAB_HEADER.SUB_OUTPUT = idsubouput
                AND T_RAB_HEADER.KOMPONEN = idkomponen
            GROUP BY  T_RAB_SUB_KOMPONEN.ID,T_RAB_COA.ID_RAB,
                     T_RAB_HEADER.TAHUN_ANGGARAN,
                     T_RAB_SUB_KOMPONEN.KODE,
                     T_RAB_SUB_KOMPONEN.URAIAN
            ORDER BY  T_RAB_SUB_KOMPONEN.KODE;
i C_SUB_KOMPONEN%ROWTYPE;

cursor C_JENIS_BELANJA (idrab in number,vKODE_KEG IN VARCHAR2, idsubkomponen IN NUMBER) IS
   select t_rab_jenis_belanja.id as id_jenis_belanja,t_rab_coa.id_sub,t_rab_coa.id_rab,t_rab_jenis_belanja.kode,t_rab_jenis_belanja.uraian,
        SUM (NVL(T_RAB_COA.JUMLAH_COA,0))AS PAGU, 
        sum(NVL(T_RAB_COA.BLOKIR,0))as BLOKIR
        from t_rab_coa
        inner join t_rab_jenis_belanja on t_rab_coa.id_sub = t_rab_jenis_belanja.id_sub_komponen 
        and t_rab_coa.id_jenis_belanja = t_rab_jenis_belanja.kode
        where id_rab = idrab 
        and id_sub = idsubkomponen
        group by t_rab_jenis_belanja.id,t_rab_coa.id_sub,t_rab_coa.id_rab,t_rab_jenis_belanja.kode,t_rab_jenis_belanja.uraian;
j C_JENIS_BELANJA%ROWTYPE;

cursor C_RAB_COA (vID_RAB in number,vKODE_KEG IN VARCHAR2, vKODE_SUB_KOMPONEN IN NUMBER, vID_JNS_BELANJA IN NUMBER) IS
    SELECT T_RAB_COA.ID_RAB,
            T_RAB_COA.KODE,
            T_RAB_COA.URAIAN AS NAMA,
            T_RAB_COA.ID_KETERANGAN,
            SUM (NVL(T_RAB_COA.JUMLAH_COA,0))AS PAGU, 
            sum(NVL(T_RAB_COA.BLOKIR,0))as BLOKIR
    FROM T_RAB_JENIS_BELANJA
    INNER JOIN T_RAB_SUB_KOMPONEN ON T_RAB_SUB_KOMPONEN.ID = T_RAB_JENIS_BELANJA.ID_SUB_KOMPONEN
    INNER JOIN T_RAB_COA ON  T_RAB_SUB_KOMPONEN.ID = T_RAB_COA.ID_SUB AND T_RAB_JENIS_BELANJA.KODE = T_RAB_COA.ID_JENIS_BELANJA
    WHERE T_RAB_COA.ID_RAB = vID_RAB
          AND T_RAB_SUB_KOMPONEN.ID = vKODE_SUB_KOMPONEN
          AND T_RAB_JENIS_BELANJA.ID = vID_JNS_BELANJA
    GROUP BY T_RAB_COA.ID_RAB, 
            T_RAB_COA.KODE,
            T_RAB_COA.URAIAN,
            T_RAB_COA.ID_KETERANGAN;
k C_RAB_COA%ROWTYPE;

cursor c_header_keterangan(idjnsbelanja in number, idsubkomponen in number, idrab in number) is
    select id as id_keterangan_header,id_jenis_belanja,keterangan
        from t_rab_keterangan_header
        where id_jenis_belanja = idjnsbelanja
        and id_sub_komponen = idsubkomponen
        and id_rab = idrab;
hk c_header_keterangan%rowtype;

cursor c_keterangan(idketeranganheader in number,idjnsbelanja in number) is
    select id,id_jenis_belanja,id_keterangan_header,sub_keterangan_1 as sub_keterangan
            from t_rab_keterangan
            where id_keterangan_header = idketeranganheader
            and id_jenis_belanja = idjnsbelanja;
ck c_keterangan%rowtype;

cursor c_rincian (idrab in number,idsubkomponen in number,idjnsbelanja in number,idketerangan in number) IS
        select * 
        from t_rab_coa
        where id_rab = idrab
            and id_sub = idsubkomponen
            and id_jenis_belanja = idjnsbelanja
            and id_keterangan = idketerangan;
cr c_rincian%ROWTYPE;

BEGIN

    case params 
        when 'detail-output' then
            begin
             strTable :=  strTable||'<table id="table'||ID||'" class="fancyTable">';
             strTable :=  strTable||'<thead>';
             strTable :=  strTable||'	<tr style="background-color: #684a96;display:none">';
             strTable :=  strTable||'		<th>#</th>';
             strTable :=  strTable||'		<th style="text-align:left !important">Kode</th>';
             strTable :=  strTable||'		<th style="text-align:left !important">Nama</th>';
             strTable :=  strTable||'		<th style="text-align:left !important">Pagu</th>';
             strTable :=  strTable||'		<th style="text-align:left !important">Blokir</th>';
             strTable :=  strTable||'	</tr>';
             strTable :=  strTable||'</thead>';
             strTable :=  strTable||'<tbody>';
            
            OPEN C_OUTPUT (ID, THN);
            loop
                fetch C_OUTPUT into g;
                exit when C_OUTPUT%notfound;
                strTable := strTable||'<tr>';
                strTable := strTable||'<td style="width:30px;border-left:0"><img id="o'||g.id
                                    ||'" src="/images/plus.png" alt="expand/collapse" data-header="'||ID||'" rel="'||g.id
                                    ||'" onclick="ExpandSub1(this)"'
                                    ||' data-prefix="'||g.kode||'"'
                                    ||' data-references="'||g.kegiatan||'.'||g.output_kegiatan||'.'||g.sub_output||'"'
                                    ||'></td>';
                strTable := strTable||'<td style="width:60px;background-color: black;color: #fff;">'||g.kode||'</td>';
                strTable := strTable||'<td>'||g.nama||'</td>';
                strTable := strTable||'<td style="text-align:right !important">'||TO_CHAR(g.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                strTable := strTable||'<td style="text-align:right !important">'||TO_CHAR(g.blokir, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                strTable := strTable||'</tr>';
            end loop;
            close C_OUTPUT;    
            strTable := strTable||'</tbody></table>';
            end;
            
        when 'detail-komponen' then
            begin
                kd_kegiatan := REGEXP_SUBSTR(KEYIN,'[^.]+');
                kd_output := REGEXP_SUBSTR(KEYIN,'[^.]+',1,2);
                kd_suboutput := REGEXP_SUBSTR(KEYIN,'[^.]+',1,3);
            
                strTable :=  strTable||'<table id="table-komponen'||ID||'" class="fancyTable">';
                 strTable :=  strTable||'<thead>';
                 strTable :=  strTable||'	<tr style="background-color: #684a96;display:none">';
                 strTable :=  strTable||'		<th>#</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Kode</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Nama</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Pagu</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Blokir</th>';
                 strTable :=  strTable||'	</tr>';
                 strTable :=  strTable||'</thead>';
                 strTable :=  strTable||'<tbody>';
                 
                 
                 OPEN cur_komponen (ID, THN,kd_kegiatan,kd_output,kd_suboutput);
                    loop
                        fetch cur_komponen into h;
                        exit when cur_komponen%notfound;
                        strTable := strTable||'<tr>';
                        strTable := strTable||'<td style="width:30px;border-left:0"><img id="o'||h.id
                                            ||'" src="/images/plus.png" alt="expand/collapse" data-header="'||ID||'" rel="'||h.id
                                            ||'" onclick="ExpandSub2(this)"'
                                            ||' data-prefix="'||h.kode||'"'
                                            ||' data-references="'||h.id_kegiatan||'.'||h.output_kegiatan||'.'||h.sub_output||'.'||h.id||'"'
                                            ||'></td>';
                        strTable := strTable||'<td style="width:60px;background-color: black;color: #fff;">'||h.kode||'</td>';
                        strTable := strTable||'<td>'||h.nama||'</td>';
                        strTable := strTable||'<td style="text-align:right !important">'||TO_CHAR(h.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                        strTable := strTable||'<td style="text-align:right !important">'||TO_CHAR(h.blokir, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                        strTable := strTable||'</tr>';
                    end loop;
                    close cur_komponen;    
                    strTable := strTable||'</tbody></table>';
            end;
            
        when 'detail-sub-komponen' then
            begin
                kd_kegiatan :=  REGEXP_SUBSTR(KEYIN,'[^.]+');
                kd_output := REGEXP_SUBSTR(KEYIN,'[^.]+',1,2);
                kd_suboutput := REGEXP_SUBSTR(KEYIN,'[^.]+',1,3);
                kd_komponen := REGEXP_SUBSTR(KEYIN,'[^.]+',1,4);
                
                
                 strTable :=  strTable||'<table id="table-sub'||ID||'" class="fancyTable">';
                 strTable :=  strTable||'<thead>';
                 strTable :=  strTable||'	<tr style="background-color: #684a96;display:none">';
                 strTable :=  strTable||'		<th>#</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Kode</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Nama</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Pagu</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Blokir</th>';
                 strTable :=  strTable||'	</tr>';
                 strTable :=  strTable||'</thead>';
                 strTable :=  strTable||'<tbody>';
                 
                 open C_SUB_KOMPONEN (THN,kd_kegiatan,kd_output,kd_suboutput,kd_komponen);
                 loop
                    fetch  C_SUB_KOMPONEN into i;
                    exit when  C_SUB_KOMPONEN%notfound;
                    strTable := strTable||'<tr>';
                    strTable := strTable||'<td style="width:30px;border-left:0"><img id="o'||i.id
                                        ||'" src="/images/plus.png" alt="expand/collapse" data-header="'||ID||'" rel="'||i.id
                                        ||'" onclick="ExpandSub3(this)"'
                                        ||' data-prefix="'||KODE_KEG||'.'||i.kode||'"'
                                        ||' data-references="'||i.id_rab||'.'||KEYIN||'.'||i.id||'"'
                                        ||'></td>';
                    strTable := strTable||'<td style="width:60px;background-color: black;color: #fff;">'||i.kode||'</td>';
                    strTable := strTable||'<td>'||i.nama||'</td>';
                    strTable := strTable||'<td style="text-align:right !important">'||TO_CHAR(i.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                    strTable := strTable||'<td style="text-align:right !important">'||TO_CHAR(i.blokir, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                    strTable := strTable||'</tr>';
                    
                 end loop;
                 close  C_SUB_KOMPONEN;
                
                strTable := strTable||'</tbody></table>';
            end;
            
            when 'detail-jenis-belanja' then
            begin
                id_rab := REGEXP_SUBSTR(KEYIN,'[^.]+');
                kd_kegiatan := REGEXP_SUBSTR(KEYIN,'[^.]+',1,2);
                kd_output := REGEXP_SUBSTR(KEYIN,'[^.]+',1,3);
                kd_suboutput := REGEXP_SUBSTR(KEYIN,'[^.]+',1,4);
                kd_komponen := REGEXP_SUBSTR(KEYIN,'[^.]+',1,5);
                kd_sub_komponen := REGEXP_SUBSTR(KEYIN,'[^.]+',1,6);
                strTable := '';            
                strTable :=  strTable||'<table id="table-jenis'||ID||'" class="table table-bordered">';
                 strTable :=  strTable||'<thead>';
                 strTable :=  strTable||'	<tr style="background-color: #684a96;display">';
                 strTable :=  strTable||'		<th>#</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Kode</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Uraian</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Pagu</th>';
                 strTable :=  strTable||'		<th style="text-align:left !important">Blokir</th>';
                 strTable :=  strTable||'	</tr>';
                 strTable :=  strTable||'</thead>';
                 strTable :=  strTable||'<tbody>';
                 strTable := strTable||'<tr>';
                 
               open C_JENIS_BELANJA (id_rab, KODE_KEG,kd_sub_komponen);
                 loop
                    fetch  C_JENIS_BELANJA into j;
                    exit when  C_JENIS_BELANJA%notfound;
                    strTable := strTable||'<tr>';
                    strTable := strTable||'<td style="width:30px;border-left:0"></td>';
                    strTable := strTable||'<td style="width:60px;">'||j.kode||'</td>';
                    strTable := strTable||'<td><b>'||j.uraian||'</b></td>';
                    strTable := strTable||'<td style="text-align:right !important"><b>'||TO_CHAR(j.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                    strTable := strTable||'<td style="text-align:right !important"><b>'||TO_CHAR(j.blokir, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                    strTable := strTable||'</tr>'; 
                    
                    
                    open c_header_keterangan(j.id_jenis_belanja,kd_sub_komponen,id_rab);
                    loop
                        fetch c_header_keterangan into hk;
                        exit when c_header_keterangan%notfound;
                        strTable := strTable||'<tr>';
                        strTable := strTable||'<td style="width:30px;border-left:0"></td>';
                        strTable := strTable||'<td style="width:60px;"></td>';
                        strTable := strTable||'<td><u>'||hk.keterangan||'</u></td>';
                        strTable := strTable||'<td></td>';
                        strTable := strTable||'<td></td>';
                        strTable := strTable||'</tr>';
                        
                        
                        open c_keterangan(hk.id_keterangan_header,hk.id_jenis_belanja);
                        loop
                            fetch c_keterangan into ck;
                            exit when c_keterangan%notfound;
                            strTable := strTable||'<tr>';
                            strTable := strTable||'<td style="width:30px;border-left:0"></td>';
                            strTable := strTable||'<td style="width:60px;"></td>';
                            strTable := strTable||'<td><i>'||ck.sub_keterangan||'</i></td>';
                            strTable := strTable||'<td></td>';
                            strTable := strTable||'<td></td>';
                            strTable := strTable||'</tr>';
                            
                            open c_rincian(id_rab,kd_sub_komponen,j.kode,ck.id);
                            loop
                                fetch c_rincian into cr;
                                exit when c_rincian%notfound;
                                strTable := strTable||'<tr>';
                                strTable := strTable||'<td style="width:30px;border-left:0"></td>';
                                strTable := strTable||'<td style="width:60px;">'||cr.kode||'</td>';
                                strTable := strTable||'<td style="padding-left:40px">'||cr.uraian||'<br>'||cr.detail||'</td>';
                                strTable := strTable||'<td style="text-align:right !important">'||TO_CHAR(cr.jumlah_coa, '999G999G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                                strTable := strTable||'<td style="text-align:right !important"><div class="input-group margin">';
                                strTable := strTable||'<input type="text" style="text-align:right" class="form-control" id="coa'||TO_CHAR(cr.id)||'" name="coa'||TO_CHAR(cr.id)||'" value="'||cr.blokir||'">';
                                strTable := strTable||'<span class="input-group-btn"><button type="button" class="btn  btn-info btn-flat" onclick="AddBlokir(this)" data-id="'||to_char(cr.id)||'" class="btn btn-block btn-info btn-sm">Save</button></span></div></td>';
                                strTable := strTable||'</tr>';
                            end loop;
                            close c_rincian;
                        
                        end loop;
                        close c_keterangan;
                        
                    end loop;
                    close c_header_keterangan;
                     
                end loop;
                close C_JENIS_BELANJA;
                strTable := strTable||'</tbody></table>';
            end;
                
    end case;
 PIPE ROW (STRTABLE_TYPE(strTable));

END AJAX_DIPA_GET_TABLE;