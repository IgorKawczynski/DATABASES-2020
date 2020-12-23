
CREATE TABLE _zbiorniki(
  id_zbiornika INT NOT NULL,
  rodzaj_wody_zbiornik VARCHAR(15) NOT NULL,
  objetosc_zbiornik INT NULL,
  PRIMARY KEY (id_zbiornika));



CREATE TABLE _magazyny(
  id_magazynu INT NOT NULL,
  ilosc_butelek INT NULL,
  ilosc_folii INT NULL,
  ilosc_etykiet INT NULL,
  PRIMARY KEY (id_magazynu));


CREATE TABLE _pracownicy_dane(
  pesel CHAR(11) NOT NULL,
  imie VARCHAR(18) NOT NULL,
  nazwisko VARCHAR(25) NOT NULL,
  pensja VARCHAR(12) NULL,
  konto_bankowe VARCHAR(45) NOT NULL,
  ulica VARCHAR(30) NOT NULL,
  nr_domu VARCHAR(10) NULL,
  miejscowosc VARCHAR(15) NOT NULL,
  nr_telefonu CHAR(9) NOT NULL,
  PRIMARY KEY (pesel));


CREATE TABLE _klienci(
  id_hurtownii INT NOT NULL,
  nazwa_hurtownii VARCHAR(45) NOT NULL,
  nip VARCHAR(45) NOT NULL,
  PRIMARY KEY (id_hurtownii));



CREATE TABLE _produkcja(
  id_produkcji INT NOT NULL,
  ilosc_produkcja INT NOT NULL,
  zbiorniki_id_zbiornika INT NOT NULL,
  magazyn_id_magazynu INT NOT NULL,
  _pracownicy_dane_pesel CHAR(11) NOT NULL,
  PRIMARY KEY (id_produkcji),
  INDEX fk_produkcja_zbiorniki1_idx (zbiorniki_id_zbiornika ASC) VISIBLE,
  INDEX fk_produkcja_magazyny1_idx (magazyn_id_magazynu ASC) VISIBLE,
  INDEX fk__produkcja__pracownicy_dane1_idx (_pracownicy_dane_pesel ASC) VISIBLE,
  CONSTRAINT fk_produkcja_zbiorniki1
    FOREIGN KEY (zbiorniki_id_zbiornika)
    REFERENCES _zbiorniki (id_zbiornika)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_produkcja_magazyny1
    FOREIGN KEY (magazyn_id_magazynu)
    REFERENCES _magazyny(id_magazynu)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk__produkcja__pracownicy_dane1
    FOREIGN KEY (_pracownicy_dane_pesel)
    REFERENCES _pracownicy_dane(pesel)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);



CREATE TABLE _sprzedaz(
  id_sprzedazy INT NOT NULL,
  klienci_id_hurtownii INT NOT NULL,
  kwota_sprzedazy VARCHAR(30) NULL,
  PRIMARY KEY (id_sprzedazy),
  INDEX fk_sprzedaz_klienci1_idx (klienci_id_hurtownii ASC) VISIBLE,
  CONSTRAINT fk_sprzedaz_klienci1
    FOREIGN KEY (klienci_id_hurtownii)
    REFERENCES _klienci (id_hurtownii)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_sprzedaz_produkcja1
    FOREIGN KEY (id_sprzedazy)
    REFERENCES _produkcja (id_produkcji)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);






CREATE TABLE _zamowienia_woda(
  id_zamowienia_wody INT NOT NULL,
  rodzaj_wody VARCHAR(15) NOT NULL,
  objetosc_wody INT NULL,
  kwota_wody VARCHAR(30) NULL,
  data_zamowienia_wody DATE NOT NULL,
  zbiorniki_id_zbiornika INT NOT NULL,
  PRIMARY KEY (id_zamowienia_wody),
  INDEX fk_zamowienia_woda_zbiorniki1_idx (zbiorniki_id_zbiornika ASC) VISIBLE,
  CONSTRAINT fk_zamowienia_woda_zbiorniki1
    FOREIGN KEY (zbiorniki_id_zbiornika)
    REFERENCES _zbiorniki (id_zbiornika)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);





CREATE TABLE _zamowienia_reszty(
  id_zamowienia_reszty INT NOT NULL,
  rodzaj_reszty VARCHAR(20) NOT NULL,
  ilosc_reszty INT NULL,
  kwota_reszty VARCHAR(30) NULL,
  data_zamowienia_reszty DATE NOT NULL,
  magazyny_id_magazynu INT NOT NULL,
  PRIMARY KEY (id_zamowienia_reszty),
  INDEX fk_zamowienia_reszty_magazyny1_idx (magazyny_id_magazynu ASC) VISIBLE,
  CONSTRAINT fk_zamowienia_reszty_magazyny1
    FOREIGN KEY (magazyny_id_magazynu)
    REFERENCES _magazyny (id_magazynu)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
    
    
    /* Procedura */
    
    DELIMITER $$
    CREATE PROCEDURE premia(IN peselpracownika CHAR(11))
    BEGIN
    UPDATE _pracownicy_dane SET pensja=1.15 * pensja WHERE pesel = peselpracownika;
    END
    $$
    DELIMITER ;
    
    
CALL premia('73560615146');


/* trigger napelniajacy zbiornik z wodą po dostarczeniu zamowienia wody */


DELIMITER $$
    CREATE TRIGGER napelnij_zbiornik_after_insert
    AFTER INSERT ON _zamowienia_woda
    FOR EACH ROW
    BEGIN
    IF NEW.rodzaj_wody='niegazowana'
    THEN
    UPDATE _zbiorniki SET _zbiorniki.objetosc_zbiornik=_zbiorniki.objetosc_zbiornik+NEW.objetosc_wody WHERE _zbiorniki.id_zbiornika=1;
    ELSE IF NEW.rodzaj_wody='gazowana'
    THEN
    UPDATE _zbiorniki SET _zbiorniki.objetosc_zbiornik=_zbiorniki.objetosc_zbiornik+NEW.objetosc_wody WHERE _zbiorniki.id_zbiornika=2;
    END IF;
    END IF;
    END
    $$
    DELIMITER ;
    
    
    
    /* trigger zapelniajacy magazyn danym asortymentem */



DELIMITER $$
    CREATE TRIGGER zaladuj_do_magazynu_after_insert
    AFTER INSERT ON _zamowienia_reszty
    FOR EACH ROW
    BEGIN
    IF NEW.rodzaj_reszty='folia'
    THEN
    UPDATE _magazyny SET _magazyny.ilosc_folii=_magazyny.ilosc_folii+NEW.ilosc_reszty WHERE _magazyny.id_magazynu=1;
    ELSE IF NEW.rodzaj_reszty='etykiety'
    THEN
    UPDATE _magazyny SET _magazyny.ilosc_etykiet=_magazyny.ilosc_etykiet+NEW.ilosc_reszty WHERE _magazyny.id_magazynu=1;
    ELSE IF NEW.rodzaj_reszty='butelki'
    THEN
    UPDATE _magazyny SET _magazyny.ilosc_butelek=_magazyny.ilosc_butelek+NEW.ilosc_reszty WHERE _magazyny.id_magazynu=1;
    END IF;
    END IF;
    END IF;
    END
    $$
    DELIMITER ;
    
    
    
    /* triggery oprozniajace magazyn i zbiornik po procesie produkcji */


DELIMITER $$
    CREATE TRIGGER oproznienie_zbiornika_after_insert
    AFTER INSERT ON _produkcja
    FOR EACH ROW
    BEGIN
    UPDATE _magazyny SET _magazyny.ilosc_butelek=_magazyny.ilosc_butelek-NEW.ilosc_produkcja, _magazyny.ilosc_folii=_magazyny.ilosc_folii-NEW.ilosc_produkcja, _magazyny.ilosc_etykiet=_magazyny.ilosc_etykiet-NEW.ilosc_produkcja WHERE _magazyny.id_magazynu=1;
    END
    $$
    DELIMITER ;
    

    
    DELIMITER $$
    CREATE TRIGGER oproznienie_magazynu_after_insert
    AFTER INSERT ON _produkcja
    FOR EACH ROW
    BEGIN
    UPDATE _zbiorniki SET _zbiorniki.objetosc_zbiornik=_zbiorniki.objetosc_zbiornik-NEW.ilosc_produkcja WHERE _zbiorniki.id_zbiornika=NEW.zbiorniki_id_zbiornika;
    END
    $$
    DELIMITER ;
    
    
    
    
    
    /* funkcje z parametrem wyswietlajace ile zamowien wody/asortymentu zlozono w danym miesiacu */
 
 
 
 DELIMITER $$
CREATE FUNCTION ilosc_zamowien_wody_miesiac(n INT)
    RETURNS INTEGER
BEGIN
    DECLARE ile INT;
    SELECT COUNT(DISTINCT id_zamowienia_wody) INTO @ile
    FROM _zamowienia_woda
    WHERE (MONTH(data_zamowienia_wody)) = n;
    RETURN @ile;
END 
$$
DELIMITER ;




 DELIMITER $$
CREATE FUNCTION ilosc_zamowien_reszty_miesiac(m INT)
    RETURNS INTEGER
BEGIN
    DECLARE ile INT;
    SELECT COUNT(DISTINCT id_zamowienia_reszty) INTO @ile
    FROM _zamowienia_reszty
    WHERE (MONTH(data_zamowienia_reszty)) = m;
    RETURN @ile;
END 
$$
DELIMITER ;

 
select ilosc_zamowien_wody_miesiac(1);
select ilosc_zamowien_reszty_miesiac(1);