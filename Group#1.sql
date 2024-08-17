DROP TABLE DP_MEDICAL_RECORDS;
DROP TABLE DP_FAMILY_HISTORY;
DROP TABLE DP_RISK_FACTORS;
DROP TABLE DP_PREDICTION_RESULT;
DROP TABLE DP_MEDICATIONS;
DROP TABLE DP_PREDICTION_MODEL;
DROP TABLE DP_PATIENT;
DROP SEQUENCE DP_PATIENT_PATIENTID_SEQ;
DROP SEQUENCE DP_MEDICAL_RECORDS_SEQ;
DROP SEQUENCE DP_PREDICTION_RESULT_SEQ;
DROP PROCEDURE Update_Patient_Medication;
DROP PROCEDURE PROC_PREDICTION_RESULT;
DROP PROCEDURE Add_Patient_Medication;
DROP FUNCTION FUNC_BMI_CAL;


CREATE TABLE DP_PATIENT(
    PatientID NUMBER PRIMARY KEY,
    Patient_lname VARCHAR2(10),
    Patient_fname VARCHAR2(10),
    Gender VARCHAR2(6),
    Patient_DOB DATE,
    Patient_address VARCHAR2(50),
    Phone_No NUMBER(10) UNIQUE
);

CREATE TABLE DP_MEDICAL_RECORDS(
    RecordID NUMBER UNIQUE NOT NULL,
    PatientID NUMBER NOT NULL,
    Weight NUMBER(3),
    Height NUMBER(3),
    Glucose NUMBER(4),
    BloodPressure NUMBER(4),
    SkinThickness NUMBER(4),
    Insulin NUMBER(4),
    BMI NUMBER(3),
    Time_Recorded TIMESTAMP,
    CONSTRAINT FK_PatientID_MedicalRec FOREIGN KEY (PatientID) REFERENCES DP_PATIENT(PatientID),
    CONSTRAINT PK_RecordID_PatientID PRIMARY KEY (RecordID, PatientID)
);

CREATE TABLE DP_FAMILY_HISTORY(
    HistoryID NUMBER UNIQUE NOT NULL,
    PatientID NUMBER NOT NULL,
    Family_name VARCHAR2(10),
    Family_DOB DATE,
    Relationship VARCHAR2(10),
    Has_Diabetes VARCHAR2(3),
    Diabetes_Type VARCHAR2(5),
    CONSTRAINT FK_PatientID_FHistory FOREIGN KEY (PatientID) REFERENCES DP_PATIENT(PatientID),
    CONSTRAINT PK_PatientID_HistoryID PRIMARY KEY (HistoryID, PatientID)
);

CREATE TABLE DP_RISK_FACTORS(
    FactorID NUMBER PRIMARY KEY,
    PatientID NUMBER NOT NULL,
    Physical_Activity_Level VARCHAR2(10),
    Smoking VARCHAR2(3),
    Alcohol VARCHAR2(3), 
    Diet_Habits VARCHAR2(10),
    CONSTRAINT FK_PatientID_RiskFactors FOREIGN KEY (PatientID) REFERENCES DP_PATIENT(PatientID)
);

CREATE TABLE DP_PREDICTION_MODEL(
    ModelID NUMBER PRIMARY KEY,
    Model_name VARCHAR2(10),
    Model_version VARCHAR2(5),
    Model_description VARCHAR2(255)
);

CREATE TABLE DP_PREDICTION_RESULT(
    ResultID NUMBER PRIMARY KEY,
    ModelID NUMBER NOT NULL,
    PatientID NUMBER NOT NULL,
    Has_Diabetes VARCHAR2(3),
    Diabetes_Type VARCHAR2(5),
    Probability NUMBER(3,2),
    Time_Recorded TIMESTAMP,
    CONSTRAINT FK_PatientID_Result FOREIGN KEY (PatientID) REFERENCES DP_PATIENT(PatientID),
    CONSTRAINT FK_ModelID_Result FOREIGN KEY (ModelID) REFERENCES DP_PREDICTION_MODEL(ModelID)
);

CREATE TABLE DP_MEDICATIONS(
    PatientID NUMBER,
    MedicationID NUMBER PRIMARY KEY,
    Medication_name VARCHAR2(15),
    Medication_ingredient VARCHAR2(255),
    Dosage VARCHAR2(20),
    Instructions VARCHAR2(255),
    Start_Date DATE,
    End_Date DATE,
    CONSTRAINT FK_PatientID_Medication FOREIGN KEY (PatientID) REFERENCES DP_PATIENT(PatientID)
);




CREATE SEQUENCE DP_PATIENT_PATIENTID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOCACHE
	NOCYCLE;

CREATE SEQUENCE DP_MEDICAL_RECORDS_SEQ
	START WITH 100
	INCREMENT BY 1
	NOCACHE
	NOCYCLE;
    
CREATE SEQUENCE DP_PREDICTION_RESULT_SEQ
	START WITH 900
	INCREMENT BY 1
	NOCACHE
	NOCYCLE;
    
-- Apply to tables
ALTER TABLE DP_PATIENT
  MODIFY PatientID DEFAULT DP_PATIENT_PATIENTID_SEQ.NEXTVAL;
  
ALTER TABLE DP_MEDICAL_RECORDS
  MODIFY RecordID DEFAULT DP_MEDICAL_RECORDS_SEQ.NEXTVAL;
  
ALTER TABLE DP_PREDICTION_RESULT
  MODIFY ResultID DEFAULT DP_PREDICTION_RESULT_SEQ.NEXTVAL;
  
  
  
--DP_PATIENT table
CREATE INDEX idx_Patient_lname ON DP_PATIENT(Patient_lname);
CREATE INDEX idx_Patient_fname ON DP_PATIENT(Patient_fname);

--DP_MEDICAL_RECORDS table
CREATE INDEX dpmedicalrecords_patientid_idx ON DP_MEDICAL_RECORDS(PatientID);
CREATE INDEX dpmedicalrecords_time_idx ON DP_MEDICAL_RECORDS(Time_Recorded);

--DP_FAMILY_HISTORY table
CREATE INDEX dpfamilyhistory_patientid_idx ON DP_FAMILY_HISTORY(PatientID);

--DP_PREDICTION_RESULT table
CREATE INDEX dppredresult_patientid_idx ON DP_PREDICTION_RESULT(PatientID);


CREATE OR REPLACE PACKAGE DP_PACKAGE--header
AS
    FUNCTION FUNC_BMI_CAL(
    in_weight IN DP_MEDICAL_RECORDS.WEIGHT%TYPE,
    in_height IN DP_MEDICAL_RECORDS.HEIGHT%TYPE) 
    RETURN NUMBER;
    
    FUNCTION calc_age 
    (p_id in dp_patient.patientid%type)
    return number;
    
    PROCEDURE PROC_PREDICTION_RESULT (
    p_ModelID IN DP_PREDICTION_MODEL.ModelID%TYPE,
    p_Mec_RecID IN DP_MEDICAL_RECORDS.RecordID%TYPE);
    
    PROCEDURE Add_Patient_Medication (
    pro_PatientID IN DP_MEDICATIONS.PatientID%TYPE,
    pro_MedicationName IN DP_MEDICATIONS.Medication_name%TYPE,
    pro_MedicationIngredient IN DP_MEDICATIONS.Medication_ingredient%TYPE,
    pro_Dosage IN DP_MEDICATIONS.Dosage%TYPE,
    pro_Instructions IN DP_MEDICATIONS.Instructions%TYPE,
    pro_StartDate IN DP_MEDICATIONS.Start_Date%TYPE,
    pro_EndDate IN DP_MEDICATIONS.End_Date%TYPE);
    
    PROCEDURE Calculate_Medical_Statistics (
    pro_PatientID IN DP_PATIENT.PatientID%TYPE);
END;
/

CREATE OR REPLACE PACKAGE BODY DP_PACKAGE--BODY
AS
    FUNCTION FUNC_BMI_CAL(
        in_weight IN DP_MEDICAL_RECORDS.WEIGHT%TYPE,
        in_height IN DP_MEDICAL_RECORDS.HEIGHT%TYPE)
    RETURN NUMBER
    IS
        out_bmi DP_MEDICAL_RECORDS.BMI%TYPE;
    BEGIN
        IF in_weight IS NULL OR in_weight = 0 AND in_height IS NULL OR in_height = 0 THEN
            out_bmi := -1;
            raise_application_error(-20015,'Invalid input values');
        END IF;
        IF in_height > 3 THEN
            out_bmi := -1;
            raise_application_error(-20016,'Height must be in meter and smaller than 3');
        ELSE
            out_bmi := in_weight / POWER(in_height,2);
        END IF;
        RETURN out_bmi;
        EXCEPTION
            WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
    END FUNC_BMI_CAL;
    
    
    function calc_age 
    (p_id in dp_patient.patientid%type)
    return number is 
    dob dp_patient.patient_dob%type;
    age number;
    begin 
        select patient_dob into dob from dp_patient where patientid = p_id;
        age := floor(months_between(sysdate, dob) / 12);
        return age;
    exception 
        when no_data_found then
            return null;
        when others then
            return null;
    end calc_age;
    
        
    PROCEDURE PROC_PREDICTION_RESULT (
    p_ModelID IN DP_PREDICTION_MODEL.ModelID%TYPE,
    p_Mec_RecID IN DP_MEDICAL_RECORDS.RecordID%TYPE) 
    AS
    v_PatientID DP_MEDICAL_RECORDS.PatientID%TYPE;
    v_BMI DP_MEDICAL_RECORDS.BMI%TYPE;
    v_Insulin DP_MEDICAL_RECORDS.Insulin%TYPE;
    v_Has_Diabetes DP_PREDICTION_RESULT.Has_Diabetes%TYPE;
    v_Diabetes_Type DP_PREDICTION_RESULT.Diabetes_Type%TYPE;
    v_Probability DP_PREDICTION_RESULT.Probability%TYPE;
    
    CURSOR c_medical_records IS
        SELECT PatientID, BMI, Insulin
        FROM DP_MEDICAL_RECORDS WHERE RecordID = p_Mec_RecID;
    BEGIN
    FOR medical_rec IN c_medical_records LOOP
        v_PatientID := medical_rec.PatientID;
        v_BMI := medical_rec.BMI;
        v_Insulin := medical_rec.Insulin;
        
        -- Just example
        -- Replace this with the actual prediction logic in Python
        IF v_BMI > 20 AND v_Insulin > 20 THEN
            v_Has_Diabetes := 'Yes';
            v_Diabetes_Type := 'Type2';
            v_Probability := 0.85;
        ELSE
            v_Has_Diabetes := 'No';
            v_Diabetes_Type := NULL;
            v_Probability := 0.15;
        END IF;
        
        INSERT INTO DP_PREDICTION_RESULT (ModelID, PatientID, Has_Diabetes, Diabetes_Type, Probability)
        VALUES (p_ModelID, v_PatientID, v_Has_Diabetes, v_Diabetes_Type, v_Probability);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Prediction results inserted successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END PROC_PREDICTION_RESULT;

    PROCEDURE Add_Patient_Medication (
    pro_PatientID IN DP_MEDICATIONS.PatientID%TYPE,
    pro_MedicationName IN DP_MEDICATIONS.Medication_name%TYPE,
    pro_MedicationIngredient IN DP_MEDICATIONS.Medication_ingredient%TYPE,
    pro_Dosage IN DP_MEDICATIONS.Dosage%TYPE,
    pro_Instructions IN DP_MEDICATIONS.Instructions%TYPE,
    pro_StartDate IN DP_MEDICATIONS.Start_Date%TYPE,
    pro_EndDate IN DP_MEDICATIONS.End_Date%TYPE) 
    AS
    BEGIN
        INSERT INTO DP_MEDICATIONS (
        PatientID,
        MedicationID, 
        Medication_name, 
        Medication_ingredient, 
        Dosage, 
        Instructions, 
        Start_Date, 
        End_Date
    ) VALUES (
        pro_PatientID,
        DP_MEDICAL_RECORDS_SEQ.NEXTVAL,
        pro_MedicationName,
        pro_MedicationIngredient,
        pro_Dosage,
        pro_Instructions,
        pro_StartDate,
        pro_EndDate
    );
    EXCEPTION
        WHEN OTHERS THEN
            -- Handle exceptions (e.g., invalid patient ID, constraint violations)
            DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
    END Add_Patient_Medication;
    
    
    PROCEDURE Calculate_Medical_Statistics (
    pro_PatientID IN DP_PATIENT.PatientID%TYPE) 
    AS
    records NUMBER := 0;
    avg_glucose NUMBER := 0;
    max_bp NUMBER := 0;
    min_skinthickness NUMBER := NULL;
    totalinsulin NUMBER := 0;
    p_lname DP_PATIENT.Patient_lname%TYPE;
    p_fname DP_PATIENT.Patient_fname%TYPE;
    has_db VARCHAR2(3);
    dbtype VARCHAR2(5);

    CURSOR medical_stats IS
        SELECT 
            COUNT(*) AS total_records,
            AVG(Glucose) AS average_glucose,
            MAX(BloodPressure) AS max_blood_pressure,
            MIN(SkinThickness) AS min_skin_thickness,
            SUM(Insulin) AS total_insulin,
            p.Patient_lname,
            p.Patient_fname,
            fh.Has_Diabetes,
            fh.Diabetes_Type
        FROM 
            DP_MEDICAL_RECORDS mr
        JOIN 
            DP_PATIENT p ON mr.PatientID = p.PatientID
        LEFT JOIN 
            DP_FAMILY_HISTORY fh ON p.PatientID = fh.PatientID
        WHERE 
            mr.PatientID = pro_PatientID
        GROUP BY 
            p.PatientID, p.Patient_lname, p.Patient_fname, fh.Has_Diabetes, fh.Diabetes_Type;
    BEGIN
        -- Open cursor and fetch values into variables
        OPEN medical_stats;
        FETCH medical_stats INTO 
        records,
        avg_glucose,
        max_bp,
        min_skinthickness,
        totalinsulin,
        p_lname,
        p_fname,
        has_db,
        dbtype;
        CLOSE medical_stats;

        -- Display statistics
        DBMS_OUTPUT.PUT_LINE('Displaying statistics for patient: ' || p_fname || ' ' || p_lname);
        DBMS_OUTPUT.PUT_LINE('Total Medical Records: ' || records);
        DBMS_OUTPUT.PUT_LINE('Average Glucose Level: ' || avg_glucose);
        DBMS_OUTPUT.PUT_LINE('Maximum Blood Pressure: ' || max_bp);
        DBMS_OUTPUT.PUT_LINE('Minimum Skin Thickness: ' || min_skinthickness);
        DBMS_OUTPUT.PUT_LINE('Total Insulin Administered: ' || totalinsulin);
        IF has_db = 'Yes' THEN
            DBMS_OUTPUT.PUT_LINE('Patient has diabetes');
            DBMS_OUTPUT.PUT_LINE('Diabetes Type: ' || dbtype);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Patient does not have diabetes');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No medical records found for the specified patient.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
    END Calculate_Medical_Statistics;
END;
/


CREATE OR REPLACE TRIGGER TRIGGER_ON_BMI_TIME_RECORDED
BEFORE INSERT OR UPDATE ON DP_MEDICAL_RECORDS
FOR EACH ROW
BEGIN
    :NEW.BMI := DP_PACKAGE.FUNC_BMI_CAL(:NEW.WEIGHT, :NEW.HEIGHT); 
    IF :NEW.BMI = -1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid Input. Please check the weight and height');
    END IF;
    :NEW.Time_Recorded := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER UPDATE_TIME_PREDICTION
BEFORE INSERT OR UPDATE ON DP_PREDICTION_RESULT
FOR EACH ROW
BEGIN
    :NEW.Time_Recorded := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER CHECK_DIABETES_CONDITION
BEFORE INSERT OR UPDATE ON DP_FAMILY_HISTORY
FOR EACH ROW
BEGIN
    IF LOWER(:NEW.Has_Diabetes) = 'no' AND :NEW.Diabetes_Type IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'If Has_Diabetes is No, Diabetes_Type must be empty.');
    END IF;
END;
/


-- DP_PATIENT
INSERT INTO DP_PATIENT(Patient_lname, Patient_fname, Patient_DOB, Patient_address, Gender, Phone_No) VALUES
    ('Smith', 'John', TO_DATE('1990-05-15', 'YYYY-MM-DD'), '123 Main St, Anytown, Canada', 'Male', 1234567890);
INSERT INTO DP_PATIENT(Patient_lname, Patient_fname, Patient_DOB, Patient_address, Gender, Phone_No) VALUES
    ('Johnson', 'Emily', TO_DATE('1985-09-22', 'YYYY-MM-DD'), '456 Elm St, Anycity, Canada', 'Female', 9876543210);
INSERT INTO DP_PATIENT(Patient_lname, Patient_fname, Patient_DOB, Patient_address, Gender, Phone_No) VALUES
    ('Williams', 'David', TO_DATE('1978-03-10', 'YYYY-MM-DD'), '789 Oak St, Anystate, Canada', 'Male', 1112223333);
INSERT INTO DP_PATIENT(Patient_lname, Patient_fname, Patient_DOB, Patient_address, Gender, Phone_No) VALUES
    ('Brown', 'Sarah', TO_DATE('1995-11-28', 'YYYY-MM-DD'), '321 Pine St, Anymetro, Canada', 'Female', 4445556666);
INSERT INTO DP_PATIENT(Patient_lname, Patient_fname, Patient_DOB, Patient_address, Gender, Phone_No) VALUES
    ('Jones', 'Michael', TO_DATE('1980-07-07', 'YYYY-MM-DD'), '555 Cedar St, Anysuburb, Canada', 'Male', 7778889999);
INSERT INTO DP_PATIENT(Patient_lname, Patient_fname, Patient_DOB, Patient_address, Gender, Phone_No) VALUES
    ('Garcia', 'Maria', TO_DATE('1972-12-03', 'YYYY-MM-DD'), '888 Maple St, Anyvillage, Canada', 'Female', 2223334444);
INSERT INTO DP_PATIENT(Patient_lname, Patient_fname, Patient_DOB, Patient_address, Gender, Phone_No) VALUES
    ('Martinez', 'Christ', TO_DATE('1992-02-18', 'YYYY-MM-DD'), '1010 Birch St, Anyhamlet, Canada', 'Male', 5556667777);
    
-- DP_PREDICTION_MODEL
INSERT INTO DP_PREDICTION_MODEL(ModelID, Model_name, Model_version, Model_description) VALUES
    (1, 'KNN', '1.0', 'KNN is a machine learning algorithm used for classification and regression tasks.');
INSERT INTO DP_PREDICTION_MODEL(ModelID, Model_name, Model_version, Model_description) VALUES
    (2, 'DT', '2.3', 'Decision Tree is a predictive modeling algorithm that maps observations about an item to conclusions about the items target value.');
INSERT INTO DP_PREDICTION_MODEL(ModelID, Model_name, Model_version, Model_description) VALUES
    (3, 'RF', '1.5', 'Random Forest is an ensemble learning method for classification, regression, and other tasks that operates by constructing a multitude of decision trees.');


-- DP_FAMILY_HISTORY
INSERT INTO DP_FAMILY_HISTORY (HistoryID, PatientID, Family_name, Family_DOB, Relationship, Has_Diabetes, Diabetes_Type)
VALUES (1001, 1, 'Smith', TO_DATE('1970-05-15', 'YYYY-MM-DD'), 'Mother', 'Yes', 'Type2');
INSERT INTO DP_FAMILY_HISTORY (HistoryID, PatientID, Family_name, Family_DOB, Relationship, Has_Diabetes, Diabetes_Type)
VALUES (1002, 1, 'Smith', TO_DATE('1975-08-20', 'YYYY-MM-DD'), 'Father', 'No', NULL);
INSERT INTO DP_FAMILY_HISTORY (HistoryID, PatientID, Family_name, Family_DOB, Relationship, Has_Diabetes, Diabetes_Type)
VALUES (1003, 2, 'Johnson', TO_DATE('1965-03-10', 'YYYY-MM-DD'), 'Mother', 'Yes', 'Type1');
INSERT INTO DP_FAMILY_HISTORY (HistoryID, PatientID, Family_name, Family_DOB, Relationship, Has_Diabetes, Diabetes_Type)
VALUES (1004, 2, 'Johnson', TO_DATE('1968-11-25', 'YYYY-MM-DD'), 'Father', 'Yes', 'Type2');
INSERT INTO DP_FAMILY_HISTORY (HistoryID, PatientID, Family_name, Family_DOB, Relationship, Has_Diabetes, Diabetes_Type)
VALUES (1005, 3, 'Williams', TO_DATE('1982-07-03', 'YYYY-MM-DD'), 'Mother', 'No', NULL);
INSERT INTO DP_FAMILY_HISTORY (HistoryID, PatientID, Family_name, Family_DOB, Relationship, Has_Diabetes, Diabetes_Type)
VALUES (1006, 6, 'Garcia', TO_DATE('1978-09-12', 'YYYY-MM-DD'), 'Father', 'Yes', 'Type1');
INSERT INTO DP_FAMILY_HISTORY (HistoryID, PatientID, Family_name, Family_DOB, Relationship, Has_Diabetes, Diabetes_Type)
VALUES (1007, 4, 'Brown', TO_DATE('1955-12-28', 'YYYY-MM-DD'), 'Mother', 'No', NULL);

-- DP_RISK_FACTORS
INSERT INTO DP_RISK_FACTORS (FactorID, PatientID, Physical_Activity_Level, Smoking, Alcohol, Diet_Habits)
VALUES (2001, 1, 'Active', 'No', 'No', 'Balanced');
INSERT INTO DP_RISK_FACTORS (FactorID, PatientID, Physical_Activity_Level, Smoking, Alcohol, Diet_Habits)
VALUES (2002, 2, 'Sedentary', 'Yes', 'No', 'High Sugar');
INSERT INTO DP_RISK_FACTORS (FactorID, PatientID, Physical_Activity_Level, Smoking, Alcohol, Diet_Habits)
VALUES (2003, 3, 'Moderate', 'No', 'Yes', 'Low Fiber');
INSERT INTO DP_RISK_FACTORS (FactorID, PatientID, Physical_Activity_Level, Smoking, Alcohol, Diet_Habits)
VALUES (2004, 4, 'Active', 'No', 'No', 'Balanced');
INSERT INTO DP_RISK_FACTORS (FactorID, PatientID, Physical_Activity_Level, Smoking, Alcohol, Diet_Habits)
VALUES (2005, 5, 'Active', 'Yes', 'No', 'Low Carb');
INSERT INTO DP_RISK_FACTORS (FactorID, PatientID, Physical_Activity_Level, Smoking, Alcohol, Diet_Habits)
VALUES (2006, 6, 'Sedentary', 'Yes', 'Yes', 'High Fat');
INSERT INTO DP_RISK_FACTORS (FactorID, PatientID, Physical_Activity_Level, Smoking, Alcohol, Diet_Habits)
VALUES (2007, 7, 'Moderate', 'No', 'Yes', 'Balanced');


--DP_MEDICAL_RECORDS
INSERT INTO DP_MEDICAL_RECORDS (PatientID, Weight, Height, Glucose, BloodPressure, skinthickness, Insulin)
VALUES (1, 70, 1.80, 85, 66, 29, 0);
INSERT INTO DP_MEDICAL_RECORDS (PatientID, Weight, Height, Glucose, BloodPressure, skinthickness, Insulin)
VALUES (2, 100, 1.85, 149, 66, 0, 168);
INSERT INTO DP_MEDICAL_RECORDS (PatientID, Weight, Height, Glucose, BloodPressure, skinthickness, Insulin)
VALUES (3, 66, 1.70, 183, 72, 35, 0);
INSERT INTO DP_MEDICAL_RECORDS (PatientID, Weight, Height, Glucose, BloodPressure, skinthickness, Insulin)
VALUES (4, 50, 1.66, 137, 40, 32, 0);
INSERT INTO DP_MEDICAL_RECORDS (PatientID, Weight, Height, Glucose, BloodPressure, skinthickness, Insulin)
VALUES (5, 75, 1.73, 116, 70, 45, 88);
INSERT INTO DP_MEDICAL_RECORDS (PatientID, Weight, Height, Glucose, BloodPressure, skinthickness, Insulin)
VALUES (6, 85, 1.90, 197, 60, 0, 0);
INSERT INTO DP_MEDICAL_RECORDS (PatientID, Weight, Height, Glucose, BloodPressure, skinthickness, Insulin)
VALUES (7, 66, 1.65, 78, 50, 0, 543);



--Anonymous block
declare
    pid dp_patient.patientid%type := 3; 
    age number;
begin
    age := DP_PACKAGE.calc_age(pid);
    if age is not null then
        dbms_output.put_line('Age of patient with ID ' || pid || ' is: ' || age);
    else
        dbms_output.put_line('Patient with ID ' || pid || ' not found or no birth date available.');
    end if;
end;
/



DECLARE
    p_id DP_PATIENT.PatientID%TYPE := 1; 
BEGIN
    DP_PACKAGE.CALCULATE_MEDICAL_STATISTICS(p_id);
END;
/


DECLARE
    lv_modelid DP_PREDICTION_MODEL.MODELID%TYPE := &lv_modelid;
    lv_recordid DP_MEDICAL_RECORDS.RECORDID%TYPE := &lv_recordid;
BEGIN
    DP_PACKAGE.PROC_PREDICTION_RESULT(lv_modelid, lv_recordid);
END;
/


BEGIN
    DP_PACKAGE.Add_Patient_Medication(
        pro_PatientID => 2,
        pro_MedicationName => 'Metformin',
        pro_MedicationIngredient => 'Glucophage',
        pro_Dosage => '50 mg',
        pro_Instructions => 'Take with meals (ER with evening meal)',
        pro_StartDate => TO_DATE('2024-03-18', 'YYYY-MM-DD'),
        pro_EndDate => TO_DATE('2024-04-03', 'YYYY-MM-DD')
    );
END;
/

BEGIN
    DP_PACKAGE.Add_Patient_Medication(
        pro_PatientID => 2,
        pro_MedicationName => 'Acarbose',
        pro_MedicationIngredient => 'Precose',
        pro_Dosage => '25 mg',
        pro_Instructions => 'Take with first bite of meal',
        pro_StartDate => TO_DATE('2023-07-18', 'YYYY-MM-DD'),
        pro_EndDate => TO_DATE('2023-08-03', 'YYYY-MM-DD')
    );
END;
/

BEGIN
    DP_PACKAGE.Add_Patient_Medication(
        pro_PatientID => 2,
        pro_MedicationName => 'Pioglitazone',
        pro_MedicationIngredient => 'Actos',
        pro_Dosage => '15 mg',
        pro_Instructions => 'Taken once daily',
        pro_StartDate => TO_DATE('2023-09-8', 'YYYY-MM-DD'),
        pro_EndDate => TO_DATE('2023-10-13', 'YYYY-MM-DD')
    );
END;
/

BEGIN
    DP_PACKAGE.Add_Patient_Medication(
        pro_PatientID => 2,
        pro_MedicationName => 'Rosiglitazone',
        pro_MedicationIngredient => 'Avandia',
        pro_Dosage => '2 mg',
        pro_Instructions => 'Taken twice daily',
        pro_StartDate => TO_DATE('2023-10-25', 'YYYY-MM-DD'),
        pro_EndDate => TO_DATE('2023-11-11', 'YYYY-MM-DD')
    );
END;
/

BEGIN
    DP_PACKAGE.Add_Patient_Medication(
        pro_PatientID => 2,
        pro_MedicationName => 'Exenatide',
        pro_MedicationIngredient => 'Byetta',
        pro_Dosage => '5 mg',
        pro_Instructions => 'Taken two, three, or four times daily',
        pro_StartDate => TO_DATE('2023-10-5', 'YYYY-MM-DD'),
        pro_EndDate => TO_DATE('2023-11-12', 'YYYY-MM-DD')
    );
END;
/

BEGIN
    DP_PACKAGE.Add_Patient_Medication(
        pro_PatientID => 2,
        pro_MedicationName => 'Nateglinide',
        pro_MedicationIngredient => 'Starlix',
        pro_Dosage => '60 mg',
        pro_Instructions => 'Take within 30 minutes of meal',
        pro_StartDate => TO_DATE('2022-05-15', 'YYYY-MM-DD'),
        pro_EndDate => TO_DATE('2022-06-12', 'YYYY-MM-DD')
    );
END;
/

