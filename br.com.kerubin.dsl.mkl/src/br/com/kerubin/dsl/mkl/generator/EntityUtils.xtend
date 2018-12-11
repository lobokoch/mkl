package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.BasicType
import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.ByteType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Enumeration
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.ManyToMany
import br.com.kerubin.dsl.mkl.model.ManyToOne
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.ObjectTypeReference
import br.com.kerubin.dsl.mkl.model.OneToMany
import br.com.kerubin.dsl.mkl.model.OneToOne
import br.com.kerubin.dsl.mkl.model.PublicObject
import br.com.kerubin.dsl.mkl.model.RelationshipFeatured
import br.com.kerubin.dsl.mkl.model.Service
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import java.util.List

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension org.apache.commons.lang3.StringUtils.*
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum

class EntityUtils {
	
	public static val BETWEEN_FROM = 'From'
	public static val BETWEEN_TO = 'To'
	public static val VAR_FILTER = 'filter'
	public static val LIST_FILTER_PAGE_SIZE = 'pageSize'
	public static val UNKNOWN = '<UNKNOWN>'
	
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
	
	def static boolean hasEntitySlots(Entity entity) {
		entity.slots.exists[it.isEntity]
	}
	
	def static boolean hasDate(Entity entity) {
		entity.slots.exists[it.isDate]
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
	
	def static String toWebTypeDTO(Slot slot) {
		if (slot.isDTOLookupResult) {
			return slot.asEntity.toEntityLookupResultDTOName
		}
		toWebType(slot, false)
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
	
	def static String toWebType(Slot slot) {
		toWebType(slot, true)
	}
	
	def static private String toWebType(Slot slot, boolean isEntity) {
		if (slot.slotType instanceof BasicTypeReference) {
			val webBasicType = (slot.slotType as BasicTypeReference).toWebBasicType
			return webBasicType
		}
		
		if (slot.slotType instanceof ObjectTypeReference) {
			val webObjectType = (slot.slotType as ObjectTypeReference).toWebObjectType(isEntity)
			return webObjectType
		}
		
		"<WEB_UNKNOWN1>"
	}
	
	def static BasicType getBasicType(Slot slot) {
		if (slot.slotType instanceof BasicTypeReference) {
			val basicType = (slot.slotType as BasicTypeReference).basicType
			return basicType
		}
		null
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
	
	def static String toWebObjectType(ObjectTypeReference otr, boolean isEntity) {
		val webObjectType = toJavaObjectType(otr, isEntity)
		webObjectType
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
	
	def static String getWebClass(Slot slot) {
		var class = 'ui-g-12 ui-fluid'
		if (slot.hasWebClass) 
			class += ' ' + slot.web.getStyleClass
		class
	}
	
	def static String getWebLabel(Slot slot) {
		var label = if (slot.hasWebLabel) slot.web.label else slot.translationKey.transpationKeyFunc.toString
		label
	}
	
	def static String getTranslationKey(Slot slot) {
		slot.ownerEntity.translationKey + '_' + slot.name.toFirstLower
	}
	
	def static String getTranslationKey(Entity entity) {
		val key = entity.service.translationKey + '.' + entity.name.toFirstLower
		key
	}
	
	
	def static String getTranslationKey(Service service) {
		val key = service.domain.toFirstLower + '.' + service.name.toFirstLower
		key
	}
	
	def static CharSequence getTranspationKeyFunc(String key) {
		'''{{ getTranslation('«key»') }}'''
	}
	
	def static CharSequence getTranspationKeyFunc(Slot slot) {
		val key = slot.translationKey
		'''{{ getTranslation('«key»') }}'''
	}
	
	def static toEntityWebServiceName(Entity entity) {
		entity.name.toLowerCase.removeUnderline + '.service'
	}
	
	def static toEntityWebCRUDComponentName(Entity entity) {
		'crud-' + entity.name.toLowerCase.removeUnderline + '.component'
	}
	
	def static toEntityWebListComponentName(Entity entity) {
		'list-' + entity.name.toLowerCase.removeUnderline + '.component'
	}
	
	def static toEntityWebListClassName(Entity entity) {
		entity.toDtoName + 'ListComponent'
	}
	
	def static toEntityWebModelName(Entity entity) {
		val webName = entity.toWebName 
		 '../' + webName + '/' + webName + '.model'
	}
	
	def static toWebName(Entity entity) {
		entity.name.toLowerCase.removeUnderline
	}
	
	def static toEntityName(Entity entity) {
		entity.name.toFirstUpper + "Entity"
	}
	
	def static toVarName(Entity entity) {
		entity.name.toFirstLower
	}
	
	def static toEntityDTOName(Entity entity) {
		entity.toDtoName
	}
	
	def static toWebEntityServiceName(Entity entity) {
		entity.toDtoName + 'Service'
	}
	
	def static toDtoName(Entity entity) {
		entity.name.toFirstUpper
	}
	
	
    def static toEntityLookupResultDTOName(Entity entity) {
        entity.name.toFirstUpper + 'LookupResult'
	}
	
	def static toEntityListFilterName(Entity entity) {
		entity.fieldName + 'ListFilter'
	}
	
	def static toEntityWebListItems(Entity entity) {
		entity.fieldName + 'ListItems'
	}
	
	def static toEntityWebListItemsTotalElements(Entity entity) {
		entity.fieldName + 'ListTotalElements'
	}
	
	def static toEntityListFilterPredicateName(Entity entity) {
		entity.name.toFirstUpper + 'ListFilterPredicate'
	}
	
	def static toEntityListListMethod(Entity entity) {
		entity.fieldName + 'List'
	}
	
	def static toWebEntityListSearchMethod(Entity entity) {
		entity.fieldName + 'Search'
	}
	
	def static toEntityListOnLazyLoadMethod(Entity entity) {
		entity.fieldName + 'ListOnLazyLoad'
	}
	
	def static toEntityListFilterPredicateImplName(Entity entity) {
		entity.name.toFirstUpper + 'ListFilterPredicateImpl'
	}
	
	def static toWebEntityListDeleteItem(Entity entity) {
		'delete' + entity.name.toFirstUpper
	}
	
	def static getFieldName(Slot slot) {
		slot.name.toFirstLower
	}
	
	def static getEntityFieldName(Slot slot) {
		slot.ownerEntity.fieldName + '.' + slot.fieldName
	}
	
	def static getFieldNameWeb(Slot slot) {
		'_' + slot.name.toFirstLower
	}
	
	def static getWebDropdownOptions(Slot slot) {
		slot.fieldName + 'Options'
	}
	
	def static getIsNotNull_isNullLabel(Slot slot, int index) {
		var label = slot?.listFilter?.filterOperator?.label
		label = getLabelValueByIndex(label, slot.name.toFirstUpper, index)
		label
	}
	
	def static getFilterIsBetweenLabel(Slot slot, int index) {
		var label = slot?.listFilter?.filterOperator?.label
		label = getLabelValueByIndex(label, slot.name.toFirstUpper, index)
		label
	}
	
	def static getLabelValueByIndex(String text, String defText, int index) {
		val label = text ?: defText ?: UNKNOWN
		val labelList = label.split(';')
		var result = defText
		if (labelList.size > index) {
			result = labelList.get(index)
		}
		result
	}
	
	def static getIsNotNullFieldName(Slot slot) {
		val fieldName = slot.fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper
		fieldName
	}
	
	def static getIsNullFieldName(Slot slot) {
		val fieldName = slot.fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper
		fieldName
	}
	
	def static getWebAutoCompleteSuggestions(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'AutoCompleteSuggestions'
	}
	
	def static getWebAutoCompleteMethod(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'AutoComplete'
	}
	
	def static toAutoCompleteName(Entity entity) {
		entity.name.toFirstUpper + 'AutoComplete'
	}
	
	def static toAutoCompleteName(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'AutoComplete'
	}
	
	def static toAutoCompleteDTOName(Slot slot) {
		val name = slot.toAutoCompleteName.toFirstUpper
		name
	}
	
	def static toIsBetweenOptionsVarName(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'IsBetweenOptions'
	}
	
	def static toIsBetweenOptionsSelected(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'IsBetweenOptionsSelected'
	}
	
	def static toIsBetweenFromName(Slot slot) {
		slot.fieldName + BETWEEN_FROM
	}
	
	def static toIsBetweenToName(Slot slot) {
		slot.fieldName + BETWEEN_TO
	}
	
	def static toIsBetweenOptionsOnClickMethod(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'IsBetweenOptionsOnClick'
	}
	
	def static toWebEntityFilterSearchMethod(Entity entity) {
		entity.fieldName + 'FilterSearch()'
	}
	
	def static getWebAutoComplete(Slot slot) {
		slot.fieldName + 'AutoComplete'
	}
	
	def static getEntityReplicationQuantity(Entity entity) {
		entity.fieldName + 'ReplicationQuantity'
	}
	
	def static getEntityReplicationMethod(Entity entity) {
		entity.fieldName + 'Replication()'
	}
	
	def static getFieldName(Entity entity) {
		entity.name.toFirstLower
	}
	
	def static buildMethodGet(Slot slot) {
		slot.name.buildMethodGet
	}
	
	def static buildMethodGet(String obj, Slot slot) {
		obj + '.' + slot.name.buildMethodGet
	}
	
	def static buildMethodGet(Slot slot, String obj) {
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
			return «name.toFirstLower» != null && «name.toFirstLower»;
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
	
	def static buildMethodSet(Slot slot, String obj, String param) {
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
	
	def static String getToWebBasicType(BasicTypeReference btr) {
		val basicType = btr.basicType
		if (basicType instanceof StringType) {
			"string"
		}
		else if (basicType instanceof IntegerType) {
			"number"
		}
		else if (basicType instanceof DoubleType) {
			"number"
		}
		else if (basicType instanceof MoneyType) {
			"number"
		}
		else if (basicType instanceof BooleanType) {
			"boolean"
		}
		else if (basicType instanceof DateType) {
			"Date"
		}
		else if (basicType instanceof TimeType) {
			"Date"
		}
		else if (basicType instanceof DateTimeType) {
			"Date"
		}
		else if (basicType instanceof UUIDType) {
			"string"
		}
		else if (basicType instanceof ByteType) {
			"any"
		}
		else {
			"<UNKNOWN3>"
		}
		
	}
	
	
	public static def boolean isNotNull(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
	} 
	
	public static def boolean isNull(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
	} 
	
	public static def boolean isMany(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.MANY)
	} 
	
	public static def boolean isBetween(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.BETWEEN)
	} 
}