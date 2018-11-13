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
import java.util.List

class EntityUtils {
	
	def static generateEntityImports(Entity entity) {
		'''
		«entity.imports.map[it].join('\r\n')»
		'''
	}
	
	def static String getRelationIntermediateTableName(Slot slot) {
		slot.ownerEntity.databaseName + "_" + slot.databaseName
	}
	
	def static String getEntityIdAsKey(Entity entity) {
		entity.id.databaseName
	}
	
	def static String getSlotAsEntityIdFK(Slot slot) {
		val entity = slot.asEntity
		entity.databaseName + '_' + entity.id.databaseName
	}
	
	def static String getSlotAsOwnerEntityIdFK(Slot slot) {
		val entity = slot.ownerEntity
		entity.databaseName + '_' + entity.id.databaseName
	}
	
	def public static mountName(List<String> values) {
		val result = values.map[it.replace('_', '').splitByCharacterTypeCamelCase.map[toLowerCase].join('-')].join('-')
		result
	}
	
	def private static getDatabaseName(String name) {
		name.replace('_', '').splitByCharacterTypeCamelCase.map[toLowerCase].join('_')
	}
	
	def static getDatabaseName(Slot slot) {
		slot.alias.getDatabaseName
	}
	
	def static getDatabaseName(Entity entity) {
		entity.alias.getDatabaseName
	}
	
	
	def static Entity asEntity(Slot slot) {
		val reference = slot.slotType as ObjectTypeReference
		reference.referencedType as Entity
	}
	
	def static Enumeration asEnum(Slot slot) {
		val reference = slot.slotType as ObjectTypeReference
		reference.referencedType as Enumeration
	}
	
	def static boolean isEntity(Slot slot) {
		if (slot?.slotType instanceof ObjectTypeReference) {
			val reference = (slot.slotType as ObjectTypeReference)
			return reference.referencedType instanceof Entity
		}
		return false
	}
	
	def static boolean isEnum(Slot slot) {
		if (slot?.slotType instanceof ObjectTypeReference) {
			val reference = (slot.slotType as ObjectTypeReference)
			return reference.referencedType instanceof Enumeration
		}
		return false
	}
	
	def static String toJavaTypeDTO(Slot slot) {
		if (slot.isDTOLookupResult) {
			return slot.asEntity.toEntityLookupResultDTOName
		}
		toJavaType(slot, false)
	}
	
	def static String toJavaType(Slot slot) {
		toJavaType(slot, true)
	}
	
	def static private String toJavaType(Slot slot, boolean isEntity) {
		if (slot.slotType instanceof BasicTypeReference) {
			val javaBasicType = (slot.slotType as BasicTypeReference).toJavaBasicType
			return javaBasicType
		}
		
		if (slot.slotType instanceof ObjectTypeReference) {
			val javaObjectType = (slot.slotType as ObjectTypeReference).toJavaObjectType(isEntity)
			return javaObjectType
		}
		
		"<UNKNOWN1>"
	}
	
	def static Entity getOwnerEntity(Slot slot) {
		if (slot?.ownerObject !== null && slot.ownerObject instanceof Entity) {
			return slot.ownerObject as Entity
		}
		else {
			return null
		}
	}
	
	def static Slot getRelationOppositeSlot(Slot slot) {
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
	
	def static boolean isDTOFull(Slot slot) {
		slot.relationContains && 
		(slot.isOneToOne || slot.isOneToMany) 
	}
	
	def static boolean isDTOLookupResult(Slot slot) {
		slot.isEntity && ! slot.isDTOFull
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
	
	def static boolean isToMany(Slot slot) {
		val relationship = slot?.relationship
		relationship instanceof OneToMany || relationship instanceof ManyToMany
		//slot?.relationship instanceof OneToMany || slot?.relationship instanceof ManyToMany
	}
	
	def static boolean isToOne(Slot slot) {
		val relationship = slot?.relationship
		relationship instanceof OneToOne || relationship instanceof ManyToOne
		//slot?.relationship instanceof OneToMany || slot?.relationship instanceof ManyToMany
	}
	
	def static boolean isManyToMany(Slot slot) {
		slot?.relationship instanceof ManyToMany
	}
	
	def static String toJavaObjectType(ObjectTypeReference otr, boolean isEntity) {
		val refType = otr.referencedType
		if (refType instanceof Entity) {
			val entity = refType as Entity
			val entityClassName = if (isEntity) entity.toEntityName else entity.toEntityDTOName
			return entityClassName
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
	
	def static toEntityName(Entity entity) {
		entity.name.toFirstUpper + "Entity"
	}
	
	def static toEntityDTOName(Entity entity) {
		entity.name.toFirstUpper
	}
	
	
    def static toEntityLookupResultDTOName(Entity entity) {
        entity.name.toFirstUpper + 'LookupResult'
	}
	
	def static toEntityListFilterName(Entity entity) {
		entity.name.toFirstUpper + 'ListFilter'
	}
	
	def static toEntityListFilterPredicateName(Entity entity) {
		entity.name.toFirstUpper + 'ListFilterPredicate'
	}
	
	def static toEntityListFilterPredicateImplName(Entity entity) {
		entity.name.toFirstUpper + 'ListFilterPredicateImpl'
	}
	
	def static toEntityAutoCompleteName(Entity entity) {
		entity.name.toFirstUpper + 'AutoComplete'
	}
	
	def static getFieldName(Slot slot) {
		slot.name.toFirstLower
	}
	
	def static buildMethodGet(Slot slot) {
		slot.name.buildMethodGet
	}
	
	def static buildMethodGet(String obj, Slot slot) {
		obj + '.' + slot.name.buildMethodGet
	}
	
	def static buildMethodGetEntityId(String obj, Slot slot) {
		obj.buildMethodGet(slot) + '.' + slot.asEntity.id.buildMethodGet
	}
	
	def static buildMethodGet(Entity entity) {
		entity.name.buildMethodGet
	}
	
	def static CharSequence getGetMethod(Slot slot) {
		slot.getGetMethod(null)
	}
	
	def static CharSequence getGetMethod(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + suffix?.toFirstUpper
		'''
		public «slot.toJavaType» get«name»() {
			return «name.toFirstLower»;
		}
		''' 
	}
	
	def static CharSequence getGetMethodAsBoolean(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + suffix?.toFirstUpper
		'''
		public Boolean is«name»() {
			return «name.toFirstLower»;
		}
		''' 
	}
	
	def static CharSequence getSetMethodAsBoolean(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + suffix?.toFirstUpper
		val nameFirstLower = name.toFirstLower
		'''
		public void set«name»(Boolean «nameFirstLower») {
			this.«nameFirstLower» = «nameFirstLower»;
		}
		''' 
	}
	
	def static CharSequence getGetListMethod(Slot slot) {
		'''
		public java.util.List<«slot.toJavaType»> get«slot.name.toFirstUpper»() {
			return «slot.name.toFirstLower»;
		}
		''' 
	}
	
	def static CharSequence getSetMethod(Slot slot) {
		slot.getSetMethod(null)
	}
	
	def static CharSequence getSetMethod(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + suffix?.toFirstUpper
		val nameFirstLower = name.toFirstLower
		'''
		public void set«name»(«slot.toJavaType» «nameFirstLower») {
			this.«nameFirstLower» = «nameFirstLower»;
		}
		''' 
	}
	
	def static CharSequence getSetListMethod(Slot slot) {
		val nameFirstLower = slot.name.toFirstLower
		'''
		public void set«nameFirstLower.toFirstUpper»(java.util.List<«slot.toJavaType»> «nameFirstLower») {
			this.«nameFirstLower» = «nameFirstLower»;
		}
		''' 
	}
	
	def static buildMethodGet(Slot slot, String prefix, String suffix) {
		(prefix + '.' ?: '') + 'get' + slot.name.toFirstUpper + (suffix ?: '') + '(' + ')'
	}
	
	def static buildMethodGet(String name) {
		'get' + name.toFirstUpper + '(' + ')'
	}
	
	def static buildMethodSet(Slot slot, String param) {
		slot.name.buildMethodSet(param)
	}
	
	def static buildMethodSet(String obj, Slot slot, String param) {
		obj + '.' + slot.name.buildMethodSet(param)
	}
	
	def static buildMethodConvertToDTO(Slot slot) {
		//addressDTOConverter.convertToDTO(entity.getAddress())
		slot.name.toFirstLower + 'DTOConverter.convertEntityToDto(entity.' + slot.buildMethodGet + ')' 
	}
	
	def static buildMethodConvertToListDTO(Slot slot) {
		//dto.setBenefits(benefitDTOConverter.convertListToDTO(entity.getBenefits()));
		slot.asEntity.toDTOConverterVar + '.convertListToDTO(entity.' + slot.buildMethodGet + ')' 
	}
	
	def static buildMethodSet(Entity entity, String param) {
		entity.name.buildMethodSet(param)
	}
	
	def static buildMethodSet(String name, String param) {
		'set' + name.toFirstUpper + '(' + param + ')'
	}
	
	def static toServiceName(Entity entity) {
		entity.name.toFirstUpper + "Service"
	}
	
	def static toServiceImplName(Entity entity) {
		entity.name.toFirstUpper + "ServiceImpl"
	}
	
	def static toControllerName(Entity entity) {
		entity.name.toFirstUpper + "Controller"
	}
	
	def static toDTOConverterName(Entity entity) {
		entity.name.toFirstUpper + "DTOConverter"
	}
	
	def static toDTOConverterVar(Entity entity) {
		entity.name.toFirstLower + "DTOConverter"
	}
	
	def static toRepositoryName(Entity entity) {
		var name = entity.name.toFirstUpper 
		if (entity.isBaseRepository) {
			name += 'Base'
		}
		name += "Repository"
		name
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
		else if (basicType instanceof BooleanType) {
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