package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.ByteType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.EnumType
import br.com.kerubin.dsl.mkl.model.Enumeration
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.ObjectTypeReference
import br.com.kerubin.dsl.mkl.model.PublicObject
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaPostgreSQLGenerator extends JavaSQLGenerator {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override getDatabaseName() {
		"PostgreSQL"
	}
	
	override toSQLBasicType(BasicTypeReference reference){
		val basicType = reference.basicType
		if (basicType instanceof StringType) {
			"VARCHAR(" + (basicType as StringType).length  + ")"
		}
		else if (basicType instanceof IntegerType) {
			"NUMERIC(19)"
		}
		else if (basicType instanceof DoubleType) {
			"NUMERIC(19,4)"
		}
		else if (basicType instanceof MoneyType) {
			"DECIMAL"
		}
		else if (basicType instanceof BooleanType) {
			"BOOLEAN"
		}
		else if (basicType instanceof DateType) {
			"DATE"
		}
		else if (basicType instanceof TimeType) {
			"TIME"
		}
		else if (basicType instanceof DateTimeType) {
			"TIMESTAMP"
		}
		else if (basicType instanceof UUIDType) {
			"UUID"
		}
		else if (basicType instanceof ByteType) {
			"BYTEA"
		}
		else {
			"<UNKNOWN>"
		}
	}
	
	override toSQLObjectType(ObjectTypeReference reference) {
		
		val refType = reference.referencedType
		if (refType instanceof Entity) {
			val entity = refType as Entity
			val ref = if (entity.id.slotType instanceof BasicTypeReference) 
						entity.id.slotType as BasicTypeReference 
					else 
						entity.id.asEntity.id.slotType as BasicTypeReference
			
			return toSQLBasicType(ref)
		}
		else if (refType instanceof Enumeration) {
			return if (reference.ownerSlot.enumType == EnumType.ORDINAL) 'NUMERIC(19)' else 'VARCHAR(255)'
			
		}
		else if (refType instanceof PublicObject) {
			val publicObject = refType as PublicObject
			return publicObject.name.toFirstUpper
		}
	}
	
	
	
	
	
}