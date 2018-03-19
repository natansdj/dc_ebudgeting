create or replace function AJAX_MONEV_LELANG (
vDEPT_ID IN NUMBER,
vTHN IN NUMBER,
vBLN IN NUMBER
) RETURN MONEV_LELANG_TYPE_TABLE
PIPELINED
AS
strTable clob;
id_kegiatan number;
id_output number;
id_suboutput varchar2(100);
id_komponen number;
id_sub_komponen number;
id_jns_belanja number;
id_rab number;
id_keterangan_header number;
id_keterangan number;

cursor C_PROGRAM ( idunit IN NUMBER, idthn IN NUMBER) is 
    select d.kode as kode_program,d.nama as nama_program,b.kode as kode_kegiatan,b.nama as nama_kegiatan,
      sum(nvl(e.jumlah_coa,0)) as pagu,
      sum(nvl(e.blokir,0)) as blokir,
      b.id as id_kegiatan
    from t_rab_header a inner join
        t_kegiatan_baseline b on a.kegiatan = b.id
        inner join  t_baseline_kegiatan_program  c on a.kegiatan = c.id_kegiatan
        inner join t_program_baseline d on c.id_program = d.id
        inner join t_rab_coa e on a.id = e.id_rab
    where a.tahun_anggaran = idthn
    and a.jenis = 3
    and a.status = 9
    and a.last = 1
    and unit_kerja = idunit
    group by d.kode,d.nama,b.kode,b.nama,b.id;
e C_PROGRAM%rowtype;

-- SECTION KEGIATAN
CURSOR C_KEGIATAN ( idunit IN NUMBER, idthn IN NUMBER) IS
    select b.id,b.kode as kode_kegiatan,b.nama as nama_kegiatan,
      sum(nvl(c.jumlah_coa,0)) as pagu,
      sum(nvl(c.blokir,0)) as blokir
    from t_rab_header a inner join
        t_kegiatan_baseline b on a.kegiatan = b.id
        inner join t_rab_coa c on a.id = c.id_rab
    where a.tahun_anggaran = idthn
    and a.jenis = 3
    and a.status = 9
    and a.last = 1
    and unit_kerja = idunit
    group by b.id,b.kode,b.nama;
f C_KEGIATAN%ROWTYPE;
-- END SECTION

-- SECTION OUTPUT
CURSOR C_OUTPUT ( idunit IN NUMBER, idthn IN NUMBER, idkegiatan IN NUMBER ) IS
        select d.id,d.kode as kode_output,d.nama as nama_output,
              sum(nvl(c.jumlah_coa,0)) as pagu,
              sum(nvl(c.blokir,0)) as blokir
        from t_rab_header a 
        inner join t_kegiatan_baseline b on a.kegiatan = b.id
        inner join t_rab_coa c on a.id = c.id_rab
        inner join t_baseline_output_kegiatan d on a.output_kegiatan = d.id
        where a.tahun_anggaran = idthn
        and a.jenis = 3
        and a.status = 9
        and a.last = 1
        and a.unit_kerja = idunit
        and a.kegiatan = idkegiatan
        group by d.id,d.kode,d.nama;
g C_OUTPUT%ROWTYPE;

CURSOR C_SUBOUTPUT (idunit IN NUMBER, idthn IN NUMBER, idkegiatan IN NUMBER,idoutput IN NUMBER ) IS
        select a.sub_output as id,a.deskripsi_sub_output as nama_output,
              sum(nvl(c.jumlah_coa,0)) as pagu,
              sum(nvl(c.blokir,0)) as blokir
        from t_rab_header a 
        inner join t_kegiatan_baseline b on a.kegiatan = b.id
        inner join t_rab_coa c on a.id = c.id_rab
        inner join t_baseline_output_kegiatan d on a.output_kegiatan = d.id
        where a.tahun_anggaran = idthn
            and a.jenis = 3
            and a.status = 9
            and a.last = 1
            and a.unit_kerja = idunit
            and a.kegiatan = idkegiatan
            and a.output_kegiatan = idoutput
        group by a.sub_output,a.deskripsi_sub_output;
h C_SUBOUTPUT%ROWTYPE;

CURSOR C_KOMPONEN (idunit IN NUMBER, idthn IN NUMBER, idkegiatan IN NUMBER,idoutput IN NUMBER,idsuboutput IN VARCHAR2) IS
    select b.id, b.kode, b.nama,
          sum(nvl(c.jumlah_coa,0)) as pagu,
          sum(nvl(c.blokir,0)) as blokir
    from t_rab_header a 
    inner join t_komponen_kegiatan b on a.komponen = b.id
    inner join t_rab_coa c on a.id = c.id_rab
    where a.tahun_anggaran = idthn
        and a.jenis = 3
        and a.status = 9
        and a.last = 1
        and a.unit_kerja = idunit
        and a.kegiatan = idkegiatan
        and a.output_kegiatan = idoutput
        and a.sub_output = idsuboutput
    group by b.id, b.kode, b.nama;
i C_KOMPONEN%ROWTYPE;

CURSOR C_SUBKOMPONEN (idunit IN NUMBER, idthn IN NUMBER, idkegiatan IN NUMBER,idoutput IN NUMBER,idsuboutput IN VARCHAR2,idkomponen in number) IS
    select b.id, b.kode, b.uraian as nama_sub_komponen,c.id_rab,
          sum(nvl(c.jumlah_coa,0)) as pagu,
          sum(nvl(c.blokir,0)) as blokir
    from t_rab_header a 
    inner join t_rab_sub_komponen b on a.id = b.id_rab 
    inner join t_rab_coa c on a.id = c.id_rab and b.id = c.id_sub
    where a.tahun_anggaran = idthn
        and a.jenis = 3
        and a.status = 9
        and a.last = 1
        and a.unit_kerja = idunit
        and a.kegiatan = idkegiatan
        and a.output_kegiatan = idoutput
        and a.sub_output = idsuboutput
        and a.komponen = idkomponen
    group by b.id, b.kode, b.uraian,c.id_rab;
j  C_SUBKOMPONEN%ROWTYPE;

CURSOR C_JENISBELANJA (idrab in number, idsubkomponen in number) IS
    select d.id,
           d.kode, 
          d.uraian as nama,
          sum(nvl(c.jumlah_coa,0)) as pagu,
          sum(nvl(c.blokir,0)) as blokir
    from t_rab_header a 
    inner join t_rab_coa c on a.id = c.id_rab 
    inner join t_rab_jenis_belanja d on c.id_sub = d.id_sub_komponen and c.id_jenis_belanja = d.kode
    where a.jenis = 3
        and a.status = 9
        and a.last = 1
        and a.id = idrab
        and c.id_sub = idsubkomponen
    group by d.id, d.kode, d.uraian;
k C_JENISBELANJA%ROWTYPE;

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

cursor c_rincian (idrab in number,idsubkomponen in number,idjnsbelanja in number,idketerangan in number,bln in number) IS
        select a.id,a.kode,a.uraian,a.detail,a.jenis_pengadaan,
                (NVL(A.JUMLAH_COA,0)) AS JUMLAH_COA,
                (NVL(B.NKONTRAK,0)) AS NKONTRAK 
            from t_rab_coa a
            left outer join T_MONEV_LELANG_DETAIL B ON A.ID = B.ID_COA
            where a.id_rab = idrab
            and a.id_sub = idsubkomponen
            and a.id_keterangan = idketerangan
            and a.id_jenis_belanja = idjnsbelanja;
cr c_rincian%rowtype;

CURSOR C_COA(IDSUB IN NUMBER,IDJNSBELANJA IN NUMBER) IS
    SELECT 
    A.ID,
    TO_CHAR(A.KODE) AS KODE,
    A.URAIAN,
    (NVL(A.JUMLAH_COA,0)) AS JUMLAH_COA,
    A.DETAIL,
    A.JENIS_PENGADAAN,
    (NVL(B.NKONTRAK,0)) AS NKONTRAK
    FROM T_RAB_COA A
    LEFT OUTER JOIN T_MONEV_LELANG_DETAIL B ON A.ID = B.ID_COA
    WHERE A.ID_SUB = IDSUB AND A.ID_JENIS_BELANJA = IDJNSBELANJA;
l C_COA%ROWTYPE;

BEGIN

-- HEADER PROGRAM
OPEN C_PROGRAM (vDEPT_ID,vTHN); 
    LOOP
            fetch C_PROGRAM  into e;
            exit when C_PROGRAM %notfound;
            strTable := strTable||'<tr>';
            strTable := strTable||'<td style="text-align:left !important"><b>'||e.kode_program||'</b></td>';
            strTable := strTable||'<td style="text-align:left !important"><b>'||e.kode_program||'</b></td>';
            strTable := strTable||'<td style="text-align:left !important"><b>'||e.nama_program||'</b></td>';
            strTable := strTable||'<td style="text-align:right!important"><b>'||TO_CHAR(e.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
            strTable := strTable||'<td></td>';
            strTable := strTable||'<td></td>';
            strTable := strTable||'<td></td>';
            strTable := strTable||'<td></td>';
            strTable := strTable||'</tr style=text-align:right>';
            id_kegiatan := e.id_kegiatan;
   END LOOP;
   CLOSE C_PROGRAM;

            OPEN C_KEGIATAN (vDEPT_ID,vTHN);
            LOOP
                fetch C_KEGIATAN into f;
                exit when C_KEGIATAN%notfound;
                strTable := strTable||'<tr>';
                strTable := strTable||'<td style="text-align:left !important">'||e.kode_program||'.'||f.kode_kegiatan ||'</td>';
                strTable := strTable||'<td style="text-align:left !important">'||f.kode_kegiatan||'</td>';
                strTable := strTable||'<td style="text-align:left !important"><u>'||f.nama_kegiatan||'</u></td>';
            strTable := strTable||'<td style="text-align:right!important"><b>'||TO_CHAR(f.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                strTable := strTable||'<td></td>';
                strTable := strTable||'<td></td>';
                strTable := strTable||'<td></td>';
                strTable := strTable||'<td></td>';
                strTable := strTable||'</tr style=text-align:right>';
                
                id_kegiatan := f.id;
                
                OPEN C_OUTPUT (vDEPT_ID,vTHN,f.id);
                LOOP
                    fetch C_OUTPUT into g;
                    exit when C_OUTPUT%notfound;
                    strTable := strTable||'<tr>';
                    strTable := strTable||'<td style="text-align:left !important">'||e.kode_program||'.'||f.kode_kegiatan ||'.'||g.kode_output ||'</td>';
                    strTable := strTable||'<td style="text-align:left !important">'||g.kode_output||'</td>';
                    strTable := strTable||'<td style="text-align:left !important;">'||g.nama_output||'</td>';
                    strTable := strTable||'<td style="text-align:right!important"><b>'||TO_CHAR(g.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                    strTable := strTable||'<td></td>';
                    strTable := strTable||'<td></td>';
                    strTable := strTable||'<td></td>';
                    strTable := strTable||'<td></td>';
                    strTable := strTable||'</tr style=text-align:right>';
                    
                    id_output := g.id;
                    
                    OPEN C_SUBOUTPUT (vDEPT_ID,vTHN,id_kegiatan,id_output);
                    LOOP
                        fetch C_SUBOUTPUT into h;
                        exit when C_SUBOUTPUT%notfound;
                        strTable := strTable||'<tr>';
                        strTable := strTable||'<td style="text-align:left !important">'||e.kode_program||'.'||f.kode_kegiatan ||'.'||g.kode_output ||'.'||h.id||'</td>';
                        strTable := strTable||'<td style="text-align:left !important">'||h.id||'</td>';
                        strTable := strTable||'<td style="text-align:left !important;">'||h.nama_output||'</td>';
                        strTable := strTable||'<td style="text-align:right!important"><b>'||TO_CHAR(h.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                        strTable := strTable||'<td></td>';
                        strTable := strTable||'<td></td>';
                        strTable := strTable||'<td></td>';
                        strTable := strTable||'<td></td>';
                        strTable := strTable||'</tr style=text-align:right>';
                        
                        id_suboutput := h.id;
                                                
                        OPEN C_KOMPONEN (vDEPT_ID,vTHN,id_kegiatan,id_output,id_suboutput);
                        LOOP
                            fetch C_KOMPONEN  into i;
                            exit when C_KOMPONEN %notfound;  
                            strTable := strTable||'<tr>';
                            strTable := strTable||'<td style="text-align:left !important">'||e.kode_program||'.'||f.kode_kegiatan ||'.'||g.kode_output ||'.'||h.id||'.'||i.kode||'</td>';
                            strTable := strTable||'<td style="text-align:left !important">'||i.kode||'</td>';
                            strTable := strTable||'<td style="text-align:left !important;">'||i.nama||'</td>';
                            strTable := strTable||'<td style="text-align:right!important"><b>'||TO_CHAR(i.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                            strTable := strTable||'<td></td>';
                            strTable := strTable||'<td></td>';
                            strTable := strTable||'<td></td>';
                            strTable := strTable||'<td></td>';
                            strTable := strTable||'</tr style=text-align:right>';
                            
                            id_komponen := i.id;
                            
                            OPEN C_SUBKOMPONEN (vDEPT_ID,vTHN,id_kegiatan,id_output,id_suboutput,id_komponen);
                            LOOP
                                fetch C_SUBKOMPONEN  into j;
                                exit when C_SUBKOMPONEN%notfound;
                                strTable := strTable||'<td style="text-align:left !important">'||e.kode_program||'.'||f.kode_kegiatan ||'.'||g.kode_output ||'.'||h.id||'.'||i.kode||'.'||j.kode||'</td>';
                                strTable := strTable||'<td style="text-align:left !important">'||j.kode||'</td>';
                                strTable := strTable||'<td style="text-align:left !important;">'||j.nama_sub_komponen||'</td>';
                                strTable := strTable||'<td style="text-align:right!important"><b>'||TO_CHAR(j.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                                strTable := strTable||'<td></td>';
                                strTable := strTable||'<td></td>';
                                strTable := strTable||'<td></td>';
                                strTable := strTable||'<td></td>';
                                strTable := strTable||'</tr style=text-align:right>';
                                
                                id_rab := j.id_rab;
                                id_sub_komponen := j.id;
                                
                                
--                                CURSOR C_JENISBELANJA (idrab in number, idsubkomponen in number)
                                OPEN C_JENISBELANJA (id_rab,id_sub_komponen);
                                LOOP
                                    fetch C_JENISBELANJA into k;
                                    exit when C_JENISBELANJA%notfound;
                                    strTable := strTable||'<td style="text-align:left !important">'||to_char(e.kode_program)||'.'||to_char(f.kode_kegiatan) ||'.'||to_char(g.kode_output) ||'.'||to_char(h.id)||'.'||to_char(i.kode)||'.'||to_char(j.kode)||'.'||to_char(k.kode)||'</td>';
                                    strTable := strTable||'<td style="text-align:left !important">'||to_char(k.kode)||'</td>';
                                    strTable := strTable||'<td style="text-align:left !important;">'||k.nama||'</td>';
                                    strTable := strTable||'<td style="text-align:right!important"><b>'||TO_CHAR(k.pagu, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</b></td>';
                                    strTable := strTable||'<td></td>';
                                    strTable := strTable||'<td></td>';
                                    strTable := strTable||'<td></td>';
                                    strTable := strTable||'<td></td>';
                                    strTable := strTable||'</tr style=text-align:right>';
                                    
                                    id_jns_belanja := k.id;
                                    
                                    open c_header_keterangan(id_jns_belanja,id_sub_komponen,id_rab);
                                    loop
                                        fetch c_header_keterangan into hk;
                                        exit when c_header_keterangan%notfound;
                                        strTable := strTable||'<td style="text-align:left !important"></td>';
                                        strTable := strTable||'<td style="text-align:left !important"></td>';
                                        strTable := strTable||'<td style="text-align:left !important;padding-left:20px;">'||hk.keterangan||'</td>';
                                        strTable := strTable||'<td style="text-align:right!important"></td>';
                                        strTable := strTable||'<td></td>';
                                        strTable := strTable||'<td></td>';
                                        strTable := strTable||'<td></td>';
                                        strTable := strTable||'<td></td>';
                                        strTable := strTable||'</tr style=text-align:right>';
                                        
                                        id_keterangan_header := hk.id_keterangan_header;
                                        
                                        open c_keterangan(id_keterangan_header,id_jns_belanja);
                                        loop
                                            fetch c_keterangan into ck;
                                            exit when c_keterangan%notfound;
                                            strTable := strTable||'<td style="text-align:left !important"></td>';
                                            strTable := strTable||'<td style="text-align:left !important"></td>';
                                            strTable := strTable||'<td style="text-align:left !important;padding-left:20px;">'||ck.sub_keterangan||'</td>';
                                            strTable := strTable||'<td style="text-align:right!important"></td>';
                                            strTable := strTable||'<td></td>';
                                            strTable := strTable||'<td></td>';
                                            strTable := strTable||'<td></td>';
                                            strTable := strTable||'<td></td>';
                                            strTable := strTable||'</tr style=text-align:right>';
                                            
                                            id_keterangan := ck.id;
                                                                                
                                            open c_rincian(id_rab,id_sub_komponen,k.kode,id_keterangan,vBLN);
                                            loop
                                                fetch c_rincian into cr;
                                                exit when c_rincian%notfound;
                                                strTable := strTable||'<td style="text-align:left !important"></td>';
                                                strTable := strTable||'<td style="text-align:left !important">'||to_char(cr.kode)||'</td>';
                                                strTable := strTable||'<td style="text-align:left !important; padding-left: 30px;">'||cr.uraian||'</td>';
                                                strTable := strTable||'<td style="text-align:right!important">'||TO_CHAR(cr.jumlah_coa, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                                                strTable := strTable||'<td style="text-align:left !important">'||cr.detail||'</td>';
                                                strTable := strTable||'<td style="text-align:right!important">'||TO_CHAR(cr.nkontrak, '99G999G999G999G999', 'NLS_NUMERIC_CHARACTERS="."')||'</td>';
                                                IF (cr.jenis_pengadaan>0) then
                                                    strTable := strTable||'<td><a href="#" rel="' ||to_char(cr.id) || '" data-jumlah="'||to_char(cr.jumlah_coa)||'" class="btn btn-sm btn-primary btn-flat" onclick="showModal(1,this)" data-toggle="modal" data-target="#myModal">Edit</a></td>';
                                                else
                                                    strTable := strTable||'<td></td>';
                                                end if;
                                                 IF (cr.jenis_pengadaan=0) then
                                                    strTable := strTable||'<td><a href="#" rel="' ||to_char(cr.id) || '" data-jumlah="'||to_char(cr.jumlah_coa)||'" class="btn btn-sm btn-primary btn-flat" onclick="showModal(2,this)" data-toggle="modal" data-target="#myModal">Edit</a></td>';
                                                 else
                                                    strTable := strTable||'<td></td>';
                                                 end if;
                                                strTable := strTable||'</tr style=text-align:right>';
                                                
                                            end loop;
                                            close c_rincian;
                                            
                                        end loop;
                                        close c_keterangan;
                                    
                                    end loop;
                                    close c_header_keterangan;
                                
                                END LOOP;
                                CLOSE C_JENISBELANJA;
                            
                            END LOOP;
                            CLOSE C_SUBKOMPONEN;
                            
                        END LOOP;
                        CLOSE C_KOMPONEN;
                        
                    END LOOP;
                    CLOSE C_SUBOUTPUT;

                END LOOP;
                CLOSE C_OUTPUT;
                
            END LOOP;
            CLOSE C_KEGIATAN;

PIPE ROW (MONEV_LELANG_TYPE(e.kode_program,e.nama_program,strTable));

END AJAX_MONEV_LELANG;