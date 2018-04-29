package br.com.kerubin.dsl.mkl.generator

import static extension org.apache.commons.lang3.StringUtils.*
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.ObjectTypeReference
import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import br.com.kerubin.dsl.mkl.model.ByteType
import br.com.kerubin.dsl.mkl.model.Enumeration
import br.com.kerubin.dsl.mkl.model.PublicObject
import br.com.kerubin.dsl.mkl.model.OneToMany
import br.com.kerubin.dsl.mkl.model.ManyToMany
import br.com.kerubin.dsl.mkl.model.RelationshipFeatured
import br.com.kerubin.dsl.mkl.model.OneToOne
import br.com.kerubin.dsl.mkl.model.ManyToOne

class EntityUtils {
	
	def static String getRelationIntermediateTableName(Slot slot) {
		slot.ownerEntity.name.databaseName + "_" + slot.name.databaseName + "_" + slot.asEntity.name.databaseName
	}
	
	def static String getEntityIdAsFKFieldName(Entity entity) {
		entity.name.databaseName + '_' + entity.id.name.databaseName
	}
	
	def static String getSlotIdAsFKFieldName(Slot slot) {
		slot.name.databaseName + '_' + slot.asEntity.id.name.databaseName
	}
	
	def static getDatabaseName(String actualName) {
		val databaseName = actualName.replace('_', '').splitByCharacterTypeCamelCase.map[toLowerCase].join('_')
		databaseName
	}
	
	def static Entity asEntity(Slot slot) {
		val reference = slot.slotType as ObjectTypeReference
		reference.referencedType as Entity
	}
	
	def static boolean isEntity(Slot slot) {
		if (slot?.slotType instanceof ObjectTypeReference) {
			val reference = (slot.slotType as ObjectTypeReference)
			return reference.referencedType instanceof Entity
		}
		return false
	}
	
	def static String getToJavaType(Slot slot) {
		if (slot.slotType instanceof BasicTypeReference) {
			val javaBasicType = (slot.slotType as BasicTypeReference).toJavaBasicType
			return javaBasicType
		}
		
		if (slot.slotType instanceof ObjectTypeReference) {
			val javaObjectType = (slot.slotType as ObjectTypeReference).toJavaObjectType
			return javaObjectType
		}
		
		"<UNKNOWN1>"
	}
	
	def static Entity getOwnerEntity(Slot slot) {
		if (slot.ownerObject !== null && slot.ownerObject instanceof Entity) {
			return slot.ownerObject as Entity
		}
	}
	
	def static Slot getRelationField(Slot slot) {
		(slot.relationship as RelationshipFeatured).field		
	}
	
	def static boolean isBidirectional(Slot slot) {
		if (slot.relationship !== null) {
			val relationshipFeatured = slot.relationship as RelationshipFeatured
			if (relationshipFeatured.field !== null) {
				val result = relationshipFeatured.field.asEntity.name == slot.ownerEntity.name
				return result
			}
		}
		
		false
	}
	
	def static boolean isOneToOne(Slot slot) {
		slot?.relationship instanceof OneToOne
	}
	
	def static boolean isManyToOne(Slot slot) {
		slot?.relationship instanceof ManyToOne
	}
	
	def static boolean isOneToMany(Slot slot) {
		slot?.relationship instanceof OneToMany
	}
	
	def static boolean isManyToMany(Slot slot) {
		slot?.relationship instanceof ManyToMany
	}
	
	def static String getToJavaObjectType(ObjectTypeReference otr) {
		val refType = otr.referencedType
		if (refType instanceof Entity) {
			val entity = refType as Entity
			return entity.toEntityName
		}
		else if (refType instanceof Enumeration) {
			val enum = refType as Enumeration
			return enum.name.toFirstUpper
		}
		else if (refType instanceof PublicObject) {
			val publicObject = refType as PublicObject
			return publicObject.name.toFirstUpper
		}
		
		"<UNKNOWN2>"
	}
	
	def static getToEntityName(Entity entity) {
		entity.name.toFirstUpper + "Entity"
	}
	
	def static String getToJavaBasicType(BasicTypeReference btr) {
		val basicType = btr.basicType
		if (basicType instanceof StringType) {
			"String"
		}
		else if (basicType instanceof IntegerType) {
			"Long"
		}
		else if (basicType instanceof DoubleType) {
			"Double"
		}
		else if (basicType instanceof MoneyType) {
			"java.math.BigDecimal"
		}
		else if (btr instanceof BooleanType) {
			"Boolean"
		}
		else if (basicType instanceof DateType) {
			"java.time.LocalDate"
		}
		else if (basicType instanceof TimeType) {
			"java.time.LocalTime"
		}
		else if (basicType instanceof DateTimeType) {
			"java.util.Date"
		}
		else if (basicType instanceof UUIDType) {
			"java.util.UUID"
		}
		else if (basicType instanceof ByteType) {
			"byte[]"
		}
		else {
			"<UNKNOWN3>"
		}
		
	}
}