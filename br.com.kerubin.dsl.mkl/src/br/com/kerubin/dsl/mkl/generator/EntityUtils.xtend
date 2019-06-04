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
import br.com.kerubin.dsl.mkl.model.RuleTarget

class EntityUtils {
	
	public static val BETWEEN_FROM = 'From'
	public static val BETWEEN_TO = 'To'
	public static val VAR_FILTER = 'filter'
	public static val LIST_FILTER_PAGE_SIZE = 'pageSize'
	public static val UNKNOWN = '<UNKNOWN>'
	public static val I18N_DEF = 'pt-br.json'
	public static val I18N_PATH_NAME = 'i18n'
	public static val ENUMS_PATH_NAME = 'enums'
	public static val NAVBAR = 'navbar'
	public static val NAVBAR_SELECTOR_NAME = 'app-' + NAVBAR
	public static val DELETED_FIELD_NAME = 'deleted'
	public static val DELETED_FIELD_LABEL = 'inativo'
	
	def static generateEntityImports(Entity entity) {
		'''
		�entity.imports.map[it].join('\r\n')�
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
	
	def static toConstantName(String name) {
		name.replace('_', '').splitByCharacterTypeCamelCase.map[toUpperCase].join('_')
	}
	
	def static getDatabaseName(Slot slot) {
		slot.alias.getDatabaseName
	}
	
	def static getDatabaseName(Entity entity) {
		entity.alias.getDatabaseName
	}
	
	
	/*def static Entity asEntity(Slot slot) {
		val reference = slot.slotType as ObjectTypeReference
		reference.referencedType as Entity
	}
	
	def static Enumeration asEnum(Slot slot) {
		val reference = slot.slotType as ObjectTypeReference
		reference.referencedType as Enumeration
	}*/
	
	def static boolean hasEntitySlots(Entity entity) {
		entity.slots.exists[it.isEntity]
	}
	
	def static boolean hasDate(Entity entity) {
		entity.slots.exists[it.isDate]
	}
	
	/*def static boolean isEntity(Slot slot) {
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
	}*/
	
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
	
	def static String toJavaTypeForEntityEvent(Slot slot) {
		if (slot.isEntity) { // returns the entity id
			return toJavaType(slot.asEntity.id, false)
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
		var label = if (slot.hasWebLabel) slot.web.label else slot.translationKey.translationKeyFunc.toString
		label
	}
	
	def static String getTranslationKey(Slot slot) {
		slot.ownerEntity.translationKey + '_' + slot.name.toFirstLower
	}
	
	def static String getTranslationKeyGrid(Slot slot) {
		slot.getTranslationKey + '_grid'
	}
	
	def static String getTranslationKey(Entity entity) {
		val key = entity.service.translationKey + '.' + entity.name.toFirstLower
		key
	}
	
	def static String getLabelValue(Entity entity) {
		val label = entity.label ?: entity.translationKey
		label
	}
	
	def static String getLabelValue(Slot slot) {
		var slotLabel = slot.label
		if (isEmpty(slotLabel) && slot.isEnum) {
			val slotAsEnum = slot.asEnum
			if (slotAsEnum.hasLabel) {
				slotLabel = slotAsEnum.label
			}
		}
		
		val label = slotLabel ?: slot.translationKey
		label
	}
	
	def static String getLabelGridValue(Slot slot) {
		val label = slot.labelGrid ?: slot.getLabelValue
		label
	}
	
	
	def static String getTranslationKey(Service service) {
		val key = service.domain.toFirstLower + '.' + service.name.toFirstLower
		key
	}
	
	def static CharSequence getTranslationKeyFunc(String key) {
		'''{{ getTranslation('�key�') }}'''
	}
	
	def static CharSequence getTranslationKeyFunc(Slot slot) {
		val key = slot.translationKey
		'''{{ getTranslation('�key�') }}'''
	}
	
	def static CharSequence getTranslationKeyGridFunc(Slot slot) {
		val key = slot.translationKeyGrid
		'''{{ getTranslation('�key�') }}'''
	}
	
	def static CharSequence getTranslationKeyFunc(Slot slot, String suffix) {
		val key = slot.translationKey
		'''{{ getTranslation('�key�' + '_' + �suffix�) }}'''
	}
	
	def static toEntityWebCRUDComponentName(Entity entity) {
		'crud-' + entity.toEntityWebComponentName
	}
	
	def static toEntityWebListComponentName(Entity entity) {
		'list-' + entity.toEntityWebComponentName
	}
	
	def static toWebAppComponentName() {
		'app.component'
	}
	
	def static toWebNavbarComponentName() {
		'navbar.component'
	}
	
	def static toWebNavbarClassName() {
		'NavbarComponent'
	}
	
	def static toWebAppModuleName() {
		'app.module'
	}
	
	def static toWebAppRoutingModuleName() {
		'app-routing.module'
	}
	
	def static buildTranslationMethod(Service service) {
		'''
		// TODO: tempor�rio, s� para testes.
		getTranslation(key: string): string {
			const value = this.�service.toTranslationServiceVarName�.getTranslation(key);
			return value;
			
			// const result = key.substring(key.lastIndexOf('_') + 1);
			// return result;
		}
		'''
	}
	
	def static toEntityWebComponentName(Entity entity) {
		entity.name.toLowerCase.removeUnderline + '.component'
	}
	
	def static toEntityWebListClassName(Entity entity) {
		entity.toDtoName + 'ListComponent'
	}
	
	def static toEntityWebServiceClassName(Entity entity) {
		entity.toDtoName + 'Service'
	}
	
	def static toEntityWebModuleClassName(Entity entity) {
		entity.toDtoName + 'Module'
	}
	
	def static toEntityWebRoutingModuleClassName(Entity entity) {
		entity.toDtoName + 'RoutingModule'
	}
	
	def static toEntityWebComponentClassName(Entity entity) {
		entity.toDtoName + 'Component'
	}
	
	def static toEnumModelName(Service service) {
		val name = service.domain.webName + '-' + service.name.webName + '-enums.model'
		name
	}
	
	def static toEntityWebModelNameWithPah(Entity ownerEntity, Slot slot) {
		var name = UNKNOWN
		if (slot.isEntity) {
			val slotAsEntity = slot.asEntity
			if (ownerEntity.isSameEntity(slotAsEntity)) { // It is circular reference
				name = slotAsEntity.toEntityWebModelName					
			}
			else {
				name = slotAsEntity.toEntityWebModelNameWithPah
			}
		}
		
		name
	}
	
	def static toEntityWebServiceNameWithPah(Entity ownerEntity, Slot slot) {
		var name = UNKNOWN
		if (slot.isEntity) {
			val slotAsEntity = slot.asEntity
			if (ownerEntity.isSameEntity(slotAsEntity)) { // It is circular reference
				name = slotAsEntity.toEntityWebServiceName					
			}
			else {
				name = slotAsEntity.toEntityWebServiceNameWithPath
			}
		}
		
		name
	}
	
	def static toEntityWebPath(Entity entity) {
		val webName = entity.toWebName 
		 val path = '../' + webName + '/'
		 path
	}
	
	def static toEntityWebServiceNameWithPath(Entity entity) {
		val path = entity.toEntityWebPath
		val name = entity.toEntityWebServiceName
		val nameWithPah = path + name
		nameWithPah
	}
	
	def static toEntityWebServiceName(Entity entity) {
		val webName = entity.toWebName 
		val name = webName + '.service'
		name
	}
	
	def static toEntityWebModuleName(Entity entity) {
		val webName = entity.toWebName 
		val name = webName + '.module'
		name
	}
	
	def static toEntityWebRoutingModuleName(Entity entity) {
		val webName = entity.toWebName 
		val name = webName + '-routing.module'
		name
	}
	
	def static toEntityWebModelNameWithPah(Entity entity) {
		val path = entity.toEntityWebModelPath
		val name = entity.toEntityWebModelName
		val nameWithPah = path + name
		nameWithPah
	}
	
	def static toEntityWebModelName(Entity entity) {
		val webName = entity.toWebName 
		val name = webName + '.model'
		name
	}
	
	def static toEntityWebModelPath(Entity entity) {
		val webName = entity.toWebName 
		 val path = '../' + webName + '/'
		 path
	}
	
	def static toWebName(Entity entity) {
		entity.name.toLowerCase.removeUnderline
	}
	
	def static toEntityName(Entity entity) {
		entity.name.toFirstUpper + "Entity"
	}
	
	def static getRuleActions(Entity entity) {
		entity.rules.filter[it.targets.exists[it == RuleTarget.GRID_ACTIONS]] 
	}
	
	def static getRuleSubscribe(Entity entity) {
		entity.rules.filter[it.targets.exists[it == RuleTarget.SUBSCRIBE]] 
	}
	
	def static getRuleMakeCopies(Entity entity) {
		entity.rules.filter[it.targets.exists[it == RuleTarget.FORM]].filter[it.apply.hasMakeCopiesExpression]
	}
	
	def static hasRuleActions(Entity entity) {
		!entity.ruleActions.empty 
	}
	
	def static toEntityQueryDSLName(Entity entity) {
		'Q' + entity.toEntityName
	}
	
	def static toVarName(Entity entity) {
		entity.name.toFirstLower
	}
	
	def static toEntityDTOName(Entity entity) {
		entity.toDtoName
	}
	
	def static toDtoName(Entity entity) {
		entity.name.toFirstUpper
	}
	
	def static toDtoName(Enumeration enumeration) {
		enumeration.name.toFirstUpper
	}
	
	def static isSameEntity(Entity a, Entity b) {
		if (a === null && b === null) {
			return true
		}
		
		if (a === null || b === null) {
			return false
		}
		
		val result = a.name.equals(b.name)
		return result
	}
	
	
    def static toEntityLookupResultDTOName(Entity entity) {
        entity.name.toFirstUpper + 'LookupResult'
	}
	
	def static toEntityListFilterName(Entity entity) {
		entity.fieldName + 'ListFilter'
	}
	
	def static toEntityListFilterClassName(Entity entity) {
		entity.fieldName.toFirstUpper + 'ListFilter'
	}
	
	def static toEntityWebListItems(Entity entity) {
		entity.fieldName + 'ListItems'
	}
	
	def static getPublishSlots(Entity entity) {
		entity.slots.filter[isPublish]
	}
	
	def static getSumFieldSlots(Entity entity) {
		entity.slots.filter[hasSumField]
	}
	
	def static toEntityWebListItemsTotalElements(Entity entity) {
		entity.fieldName + 'ListTotalElements'
	}
	
	def static toEntityListFilterPredicateName(Entity entity) {
		entity.name.toFirstUpper + 'ListFilterPredicate'
	}
	
	def static toEntityDomainEventTypeName(Entity entity) {
		'DomainEvent'
	}
	
	def static toEntityListListMethod(Entity entity) {
		entity.fieldName + 'List'
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
	
	def static getSumFieldName(Slot slot) {
		'sum' + slot.name.toFirstUpper
	}
	
	def static getEntitySumFieldName(Slot slot) {
		slot.ownerEntity.toEntitySumFieldsName.toFirstLower + '.' + slot.sumFieldName
	}
	
	def static getEntityFieldName(Slot slot) {
		slot.ownerEntity.fieldName + '?.' + slot.fieldName
	}
	
	def static getFieldNameWeb(Slot slot) {
		'_' + slot.name.toFirstLower
	}
	
	def static getWebDropdownOptions(Slot slot) {
		val name = slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'Options'
		name
	}
	
	def static getWebDropdownOptionsInitializationMethod(Slot slot) {
		val name = 'initialize' + slot.webDropdownOptions.toFirstUpper
		name
	}
	
	def static getIsNotNull_isNullLabel(Slot slot, int index) {
		var label = slot?.listFilter?.filterOperator?.label
		label = getLabelValueByIndex(label, slot.name.toFirstUpper, index)
		label
	}
	
	def static getIsNotNull_isNullSelected_OLD(Slot slot) {
		val index = 2 // xxx;yyy;0|1
		var label = slot?.listFilter?.filterOperator?.label
		label = getLabelValueByIndex(label, slot.name.toFirstUpper, index)
		val selectedIndex = try { Integer.parseInt(label.trim) } catch(Exception e) { 0 }
		selectedIndex
	}
	
	def static getIsNotNull_isNullSelected(Slot slot) {
		var def = slot?.listFilter?.filterOperator?.def ?: null
		val value = if ('isNotNull'.equalsIgnoreCase(def)) 0 else 1
		value
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
	
	def static getWebAutoCompleteFieldConverter(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'AutoCompleteFieldConverter'
	}
	
	def static getWebAutoCompleteMethod(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'AutoComplete'
	}
	
	def static toEntityAutoCompleteMethodName(Entity entity) {
		entity.fieldName + 'AutoComplete'
	}
	
	def static toAutoCompleteName(Entity entity) {
		val name = entity.toAutoCompleteClassName
		name
	}
	
	def static toTranslationServiceClassName(Service service) {
		val name = service.domain.toCamelCase + service.name.toCamelCase + 'TranslationService'
		name
	}
	
	def static toTranslationServiceName(Service service) {
		val name = service.domain.toLowerCase.removeUnderline + '-' + service.name.toLowerCase.removeUnderline + '-translation.service'
		name
	}
	
	def static toTranslationServiceVarName(Service service) {
		val name = service.domain.toCamelCase.toFirstLower + service.name.toCamelCase + 'TranslationService'
		name
	}
	
	def static toEntityEventName(Entity entity) {
		entity.toDtoName + 'Event'
	}
	
	def static toEntitySumFieldsName(Entity entity) {
		entity.toDtoName + 'SumFields'
	}
	
	def static toEntityMakeCopiesName(Entity entity) {
		entity.toDtoName + 'MakeCopies'
	}
	
	def static toEntityEventConstantName(Entity entity, String eventName) {
		entity.toDtoName.toConstantName + '_' + eventName.toUpperCase
	}
	
	def static generateNoArgsConstructor(String className) {
		className.generateConstructor(null, true, false)
	}
	
	def static generateConstructor(String className, Iterable<Slot> slots, boolean noArgsConstructor, boolean allArgsConstructor) {
		'''
		�IF noArgsConstructor�
		
		public �className�() {
			
		}
		�ENDIF�
		�IF allArgsConstructor�
		
		public �className�(�slots.map[it.buildFieldAndType].join(', ')�) {
			�slots.map[it.buildFieldThis].join('\n')�
		}
		�ENDIF�
		'''
	}
	
	def static String buildFieldThis(Slot slot) {
		val fileName = slot.name.toFirstLower
		'''this.�fileName� = �fileName�;'''.toString
	}
	
	
	
	def static CharSequence buildField(Slot slot) {
		'''private �slot.toJavaTypeDTO� �slot.name.toFirstLower�;'''
	}
	
	def static String buildFieldAndType(Slot slot) {
		'''�slot.toJavaTypeForEntityEvent� �slot.name.toFirstLower�'''.toString
	}
	
	def static toAutoCompleteClassName(Entity entity) {
		entity.toDtoName + 'AutoComplete'
	}
	
	def static toAutoCompleteName(Slot slot) {
		slot.ownerEntity.fieldName + slot.name.toFirstUpper + 'AutoComplete'
	}
	
	def static toAutoCompleteClearMethodName(Slot slot) {
		slot.toAutoCompleteName + 'Clear'
	}
	
	def static toAutoCompleteDTOName(Slot slot) {
		val name = slot.toAutoCompleteClassName
		name
	}
	
	def static toAutoCompleteClassName(Slot slot) {
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
	
	def static getDefaultOrderedField(Entity entity) {
		val slot = entity.slots.tail.findFirst[it.isOrderedOnGrid] ?: entity.id
		slot.fieldName
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
	
	def static String buildMethodGetEntityId(String obj, Slot slot) {
		'''�obj.buildMethodGet(slot)� != null ? �obj.buildMethodGet(slot)�.�slot.asEntity.id.buildMethodGet� : null'''
	}
	
	def static buildMethodGetEntityId2(String obj, Slot slot) {
		obj.buildMethodGet(slot) + '.' + slot.asEntity.id.buildMethodGet
	}
	
	def static buildMethodGet(Entity entity) {
		entity.name.buildMethodGet
	}
	
	def static CharSequence getGetMethod(Slot slot) {
		slot.getGetMethod(null)
	}
	
	def static CharSequence getGetMethod(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + (suffix?.toFirstUpper ?: '')
		'''
		public �slot.toJavaType� get�name�() {
			return �name.toFirstLower�;
		}
		''' 
	}
	
	def static CharSequence getGetMethod(Slot slot, String prefix, String suffix) {
		val name = prefix.toFirstUpper + slot.name.toFirstUpper + suffix?.toFirstUpper
		'''
		public �slot.toJavaType� get�name�() {
			return �name.toFirstLower�;
		}
		''' 
	}
	
	def static CharSequence getGetMethodAsBoolean(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + suffix?.toFirstUpper
		'''
		public Boolean is�name�() {
			return �name.toFirstLower� != null && �name.toFirstLower�;
		}
		''' 
	}
	
	def static CharSequence getSetMethodAsBoolean(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + suffix?.toFirstUpper
		val nameFirstLower = name.toFirstLower
		'''
		public void set�name�(Boolean �nameFirstLower�) {
			this.�nameFirstLower� = �nameFirstLower�;
		}
		''' 
	}
	
	def static CharSequence getGetListMethod(Slot slot) {
		'''
		public java.util.List<�slot.toJavaType�> get�slot.name.toFirstUpper�() {
			return �slot.name.toFirstLower�;
		}
		''' 
	}
	
	def static CharSequence getSetMethod(Slot slot) {
		slot.getSetMethod(null)
	}
	
	def static CharSequence getSetMethod(Slot slot, String suffix) {
		val name = slot.name.toFirstUpper + (suffix?.toFirstUpper ?: '')
		val nameFirstLower = name.toFirstLower
		'''
		public void set�name�(�slot.toJavaType� �nameFirstLower�) {
			this.�nameFirstLower� = �nameFirstLower�;
		}
		''' 
	}
	
	def static CharSequence getSetMethod(Slot slot, String prefix, String suffix) {
		val name = prefix.toFirstUpper + slot.name.toFirstUpper + suffix?.toFirstUpper
		val nameFirstLower = name.toFirstLower
		'''
		public void set�name�(�slot.toJavaType� �nameFirstLower�) {
			this.�nameFirstLower� = �nameFirstLower�;
		}
		''' 
	}
	
	def static CharSequence getSetListMethod(Slot slot) {
		val nameFirstLower = slot.name.toFirstLower
		'''
		public void set�nameFirstLower.toFirstUpper�(java.util.List<�slot.toJavaType�> �nameFirstLower�) {
			this.�nameFirstLower� = �nameFirstLower�;
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
	
	def static toSubscriberEventRabbitConfigName(Entity entity) {
		entity.name.toFirstUpper + "SubscriberEventRabbitConfig"
	}
	
	def static toSubscriberEventHandlerName(Entity entity) {
		entity.name.toFirstUpper + "SubscriberEventHandler"
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
			// "java.util.Date"
			"java.time.LocalDateTime"
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