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
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.ManyToMany
import br.com.kerubin.dsl.mkl.model.ManyToOne
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.ObjectTypeReference
import br.com.kerubin.dsl.mkl.model.OneToMany
import br.com.kerubin.dsl.mkl.model.OneToOne
import br.com.kerubin.dsl.mkl.model.PublicObject
import br.com.kerubin.dsl.mkl.model.RelationshipFeatured
import br.com.kerubin.dsl.mkl.model.RuleAction
import br.com.kerubin.dsl.mkl.model.RuleFunction
import br.com.kerubin.dsl.mkl.model.RuleTarget
import br.com.kerubin.dsl.mkl.model.Service
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.SmallintType
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import java.util.ArrayList
import java.util.List
import java.util.Set
import org.eclipse.emf.common.util.EList

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension org.apache.commons.lang3.StringUtils.*
import br.com.kerubin.dsl.mkl.model.AbstractRuleTarget
import br.com.kerubin.dsl.mkl.model.RuleTargetField
import br.com.kerubin.dsl.mkl.model.RuleTargetEnum
import br.com.kerubin.dsl.mkl.model.Rule

class EntityUtils {
	
	public static val BETWEEN_FROM = 'From'
	public static val BETWEEN_TO = 'To'
	public static val IS_EQUAL_TO = 'IsEqualTo'
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
	
	public static val VALIDATION_MAP_IMPORTS = #{
		'CpfOrCnpj' -> 'br.com.kerubin.api.servicecore.validator.constraint.CpfOrCnpj',
		'CPF' -> 'org.hibernate.validator.constraints.br.CPF',
		'CNPJ' -> 'org.hibernate.validator.constraints.br.CNPJ',
		'Size' -> 'javax.validation.constraints.Size',
		'Max' -> 'javax.validation.constraints.Max',
		'Min' -> 'javax.validation.constraints.Min',
		'Email' -> 'javax.validation.constraints.Email',
		'URL' -> 'org.hibernate.validator.constraints.URL',
		'EAN' -> 'org.hibernate.validator.constraints.EAN',
		'DecimalMin' -> 'javax.validation.constraints.DecimalMin',
		'DecimalMax' -> 'javax.validation.constraints.DecimalMax',
		'Future' -> 'javax.validation.constraints.Future',
		'FutureOrPresent' -> 'javax.validation.constraints.FutureOrPresent',
		'PastOrPresent' -> 'javax.validation.constraints.PastOrPresent',
		'Past' -> 'javax.validation.constraints.Past',
		'Positive' -> 'javax.validation.constraints.Positive',
		'PositiveOrZero' -> 'javax.validation.constraints.PositiveOrZero',
		'Negative' -> 'javax.validation.constraints.Negative',
		'NegativeOrZero' -> 'javax.validation.constraints.NegativeOrZero',
		'Pattern' -> 'javax.validation.constraints.Pattern',
		'Null' -> 'javax.validation.constraints.Null',
		'AssertFalse' -> 'javax.validation.constraints.AssertFalse',
		'AssertTrue' -> 'javax.validation.constraints.AssertTrue',
		'Digits' -> 'javax.validation.constraints.Digits'
	}
	
	def static boolean isAuditingSlot(Slot slot) {
		if (slot.ownerEntity.isAuditing) {
			ServiceBoosterImpl.ENTITY_AUDITING_FIELDS.exists[it == slot.name]
		} else {
			false
		}
	}
	
	def static generateEntityImports(Entity entity) {
		'''
		«entity.imports.map[it].join('\r\n')»
		'''
	}
	
	def static resolveBeanValidationImports(Slot slot) {
		val entity = slot.ownerEntity
		
		// Resolve Bean Validation imports
		val hasNotBlankValidation = slot.isRequired && slot.isString && slot !== entity.id
		val hasNotNullValidation = !hasNotBlankValidation && slot.isRequired && !slot.isSmallint && slot !== entity.id // TODO: @Version is smallint
		if (hasNotBlankValidation) {
			entity.addImport('import javax.validation.constraints.NotBlank;')
		}
		if (hasNotNullValidation) {
			entity.addImport('import javax.validation.constraints.NotNull;')
		}
		
		if (slot.isString) {
			entity.addImport('import javax.validation.constraints.Size;')
		}
		
		if (slot.hasValidations) {
			val validations = slot.validations
			validations.forEach[validation |
				var package_ = validation.package
				if (package_ === null || package_.trim.isEmpty) {
					val name = validation.name
					if (VALIDATION_MAP_IMPORTS.containsKey(name)) {
						package_ = VALIDATION_MAP_IMPORTS.get(name)
					}
					else {
						package_ = '<UNKNOWN VALIDATION IMPORT FOR VALIDATION NAME: ' + name + '>'
					}
				}
				
				package_ = 'import ' + package_ + ';'
				entity.addImport(package_)
			]
		}
	}
	
	def static List<String> resolveBeanValidationAnnotations(Slot slot) {
		val result = newArrayList();
		val entity = slot.ownerEntity
		val label = slot?.label ?: slot.name
		
		// Resolve Bean Validation imports
		val hasNotBlankValidation = slot.isRequired && slot.isString && slot !== entity.id
		val hasNotNullValidation = !hasNotBlankValidation && slot.isRequired && !slot.isSmallint && slot !== entity.id // TODO: @Version is smallint
		if (hasNotNullValidation) {
			result.add('''@NotNull(message="\"«label»\" é obrigatório.")''')
		}
		
		if (hasNotBlankValidation) {
			result.add('''@NotBlank(message="\"«label»\" é obrigatório.")''')
		}
		
		if (slot.isString) {
			val length = slot.length
			result.add('''@Size(max = «length», message = "\"«label»\" pode ter no máximo «length» caracteres.")''')
		}
		
		if (slot.hasValidations) {
			val validations = slot.validations
			validations.forEach[validation |
				val name = validation.name
				val custom = validation?.custom ?: ''
				var message = validation?.message ?: ''
				
				var str = '(' + custom
				
				if (!custom.empty && !message.empty) {
					str += ', '
				}
				
				if (!message.empty) {
					str += 'message="' + message + '"'
				}
				
				str += ')'
				
				if (str == '()') {
					str = null
				}
				
				result.add('''@«name»«IF str !== null»«str»«ENDIF»''')
			]
		}
		
		result
	}
	
	def static String getRelationIntermediateTableName(Slot slot) {
		slot.ownerEntity.databaseName + "_" + slot.databaseName
	}
	
	def static String getEntityIdAsKey(Entity entity) {
		entity.id.databaseName
	}
	
	def static String toSlotIndexName(Slot slot) {
		val entity = slot.ownerEntity
		entity.databaseName + '_' + slot.databaseName + '_idx'
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
	
	def static boolean hasDateOnly(Entity entity) {
		entity.slots.exists[isDate]
	}
	
	def static boolean hasDate(Entity entity) {
		entity.slots.exists[it.isDate || it.isDateTime || it.isTime]
	}
	
	def static boolean fieldsAsEntityHasDate(Entity entity) {
		entity.slots.filter[it.isEntity].exists[it.asEntity.hasDate]
	}
	
	def static boolean hasDate(Slot slot) {
		val result = slot.isDate || slot.isDateTime || slot.isTime
		result
	}
	
	def static boolean hasDateOnly(Slot slot) {
		val result = slot.isDate
		result
	}
	
	def static boolean hasDateTime(Entity entity) {
		entity.slots.exists[isDateTime]
	}
	
	def static String getFormatMask(Slot slot) {
		var format = '';
		if (slot.isDate) {
			format = 'YYYY-MM-DD'
		}
		else if (slot.isDateTime) {
			format = 'YYYY-MM-DD H:m:s'
		}
		else if (slot.isTime) {
			format = 'H:m:s'
		}
		return format;
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
	
	/*def static Entity getOwnerEntity(Slot slot) {
		if (slot?.ownerObject !== null && slot.ownerObject instanceof Entity) {
			return slot.ownerObject as Entity
		}
		else {
			return null
		}
	}*/
	
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
	
	def static Iterable<Slot> getEntityLookupResultSlots(Entity entity) {
		val slots = entity.slots.filter[
			it === entity.id || it.isAutoCompleteResult || it.isAutoCompleteData || (entity.hasEntityVersion && it.name.toLowerCase == 'version')
		]
		
		slots
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
	
	def static String getStyleClass(String styleClass) {
		val defaultUI_MD = '2'
		getStyleClass(styleClass, defaultUI_MD)
	}
	
	def static String getStyleClass(String styleClass, String defaultUI_MD) {
		var result = 'ui-md-' + defaultUI_MD;
		if (styleClass !== null && !styleClass.trim.isEmpty) {
			if (!styleClass.containsWord('ui-md-')) {
				result += ' ' + styleClass; 
			}
			else {
				result = styleClass
			}
		}
		
		result
		
	}
	
	def static String getWebClass(Slot slot) {
		var class = 'ui-g-12 ui-fluid'
		if (slot.hasWebClass) 
			class += ' ' + slot.web.getStyleClass
		
		if (slot.isHiddenSlot && !class.containsWord('hidden')) {
			class += ' hidden'
		}
		
		class
	}
	
	def static String getUserWebClassesArray(Slot slot) {
		if (slot.hasWebClass) {
			var styleClass = slot.web.getStyleClass
			
			 val userClassesList = styleClass.split(' ')
			 if (userClassesList !== null) {
			 	var userClasses = userClassesList.filter[it.startsWith('kb-')].map["'" + it + "'"].join(' ')
			 	if (userClasses !== null && !userClasses.trim.empty) {
			 		userClasses = '[' + userClasses + ']'
			 		return userClasses
			 	}
			 }
		}
		
		return null
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
		val label = if (slot.hasGridLabel) slot.grid.label else slot.getLabelValue
		label
	}
	
	def static String toGridShowNumberAsNegative(String fieldNameValue) {
		val methodCall = 'doShowNumberAsNegative(' + fieldNameValue + ')'
		methodCall
	}
	
	
	def static String getCalendarLocaleSettingsMethodName() {
		val methodName = 'getCalendarLocaleSettings'
		methodName
	}
	
	def static String getCalendarLocaleSettingsVarName() {
		val varName = 'calendarLocale'
		varName
	}
	
	def static String getTranslationKey(Service service) {
		val key = service.domain.toFirstLower + '.' + service.name.toFirstLower
		key
	}
	
	def static CharSequence getTranslationKeyFunc(String key) {
		'''{{ getTranslation('«key»') }}'''
	}
	
	def static CharSequence getTranslationKeyFunc(Slot slot) {
		val key = slot.translationKey
		'''{{ getTranslation('«key»') }}'''
	}
	
	def static CharSequence getTranslationKeyGridFunc(Slot slot) {
		val key = slot.translationKeyGrid
		'''{{ getTranslation('«key»') }}'''
	}
	
	def static CharSequence getTranslationKeyFunc(Slot slot, String suffix) {
		val key = slot.translationKey
		'''{{ getTranslation('«key»' + '_' + «suffix») }}'''
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
		// TODO: temporário, só para testes.
		getTranslation(key: string): string {
			const value = this.«service.toTranslationServiceVarName».getTranslation(key);
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
	
	def static toWebName(String name) {
		name.toLowerCase.removeUnderline
	}
	
	def static toEntityName(Entity entity) {
		entity.name.toFirstUpper + "Entity"
	}
	
	def static getRuleGridRows(Entity entity) {
		val rules = entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.GRID_ROWS]
		rules
	}
	
	def static getRuleActions(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.GRID_ACTIONS &&
			it.action !== null
		] 
	}
	
	def static getRuleFormActions(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM_ACTIONS]
	}
	
	def static getRulesForm(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM]
	}
	
	def static getRuleFormActionsWithFunction(Entity entity) {
		var rules = entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM_ACTIONS && 
			it.apply !== null && it.apply.hasRuleFunction]
		
		rules
	}
	
	def static getRulesFormWithDisableCUD(Entity entity) {
		var rules = entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM && 
			it.apply !== null && it.apply.hasDisableCUD]
		
		rules		
	}
	
	def static getRulesGridActionsHideCUDWebListActions(Entity entity) {
		var rules = entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.GRID_ACTIONS && 
			it.apply !== null && it.apply.hasHideCUDWebListActions]
		
		rules
	}
	
	def static getRulesGridActionsHideWebListActions(Entity entity) {
		var rules = entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.GRID_ACTIONS && 
			it.apply !== null && it.apply.hasHideWebListActions]
		
		rules
	}
	
	def static getRulesGridActionsWebActionsColumn(Entity entity) {
		var rules = entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.GRID_ACTIONS && 
			it.apply !== null && it.apply.hasWebActionsColumn]
		
		rules
	}
	
	def static toRuleFormWithDisableCUDMethodName(Entity entity) {
		entity.fieldName + 'RuleDisableCUD'
	}
	
	def static getRuleFormActionsActions(Entity entity) {
		var rules = entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM_ACTIONS && 
			it.apply !== null && it.apply.hasRuleFunction]
		rules
	}
	
	def static getRuleSubscribe(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.SUBSCRIBE] 
	}
	
	def static getRulesWithSlot(Entity entity) {
		entity?.rules?.filter[it.target instanceof RuleTargetField]
	}
	
	def static getRulesWithTargetEnum(Entity entity) {
		val rules = entity?.rules?.filter[
			val flag = it.target instanceof RuleTargetEnum
			return flag
		]
		
		rules
	}
	
	def static RuleTarget ruleAsTargetEnum(Rule rule) {
		if (rule.target !== null && rule.target instanceof RuleTargetEnum) {
			val result = (rule.target as RuleTargetEnum).target
			return result
		}
		return null
	}
	
	def static Entity getRuleOwnerEntity(Rule rule) {
		rule.owner as Entity
	}
	
	def static getRulesWithSlotAppyStyleClass(Entity entity) {
		entity.getRulesWithSlot.filter[it.apply !== null && it.apply.hasStyleClass] 
	}
	
	def static getRulesWithSlotAppyMathExpression(Entity entity) {
		entity.getRulesWithSlot.filter[it.apply !== null && it.apply.hasFieldMathExpression] 
	}
	
	def static getRuleWithSlotAppyStyleClassForSlot(Slot slot) {
		val entity = slot.ownerEntity
		val rules = entity.rulesWithSlotAppyStyleClass
		if (!rules.empty) { // TODO: for now gets only the first one.
			val rule = rules.filter[it.target.asRuleWithTargetField.target.field.name == slot.name].head
			if (rule !== null) {
				return rule
			}
		} 
		
		null
	}
	
	def static asRuleWithTargetField(AbstractRuleTarget target) {
		if (target instanceof RuleTargetField) {
			target as RuleTargetField
		}
	}
	
	def static getRuleMakeCopies(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM]
		.filter[it.apply !== null && it.apply.hasMakeCopiesExpression]
	}
	
	def static getRulesFormOnCreate(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM]
		.filter[it.when !== null && it.when.hasFormOnCreate]
	}
	
	def static getRulesFormOnInit(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM]
		.filter[it.when !== null && it.when.hasFormOnInit]
	}
	
	def static getRulesFormOnUpdate(Entity entity) {
		entity?.rulesWithTargetEnum?.filter[it.ruleAsTargetEnum == RuleTarget.FORM]
		.filter[it.when !== null && it.when.hasFormOnUpdate]
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
	
	def static String getBasePackage(Service service) {
		service.configuration.groupId
	}
	
	def static String getServicePackage(Service service) {
		service.basePackage + '.' + service.domain.removeUnderline + '.' + service.name.removeUnderline
	}
	
	def static String getPackage(Entity entity) {
		entity.service.servicePackage + '.entity.' + entity.name.toLowerCase
	}
	
	def static String getEnumPackage(Enumeration enumeration) {
		getServicePackage(enumeration.service) + '.' + enumeration.name.toFirstUpper
	}
	
	def static String resolveSlotAutocomplete(Slot slot, Set<String> imports) {
		if (slot.isEntity) { // If slot is an entity, returns its autocomplete class name version.
			val entity = slot.asEntity
			val autoCompleteName = entity.toAutoCompleteName
			val entityPackage = entity.package
			imports.add('import ' + entityPackage + '.' + autoCompleteName + ';')
			return autoCompleteName
		} 
		
		if (slot.isEnum) {
			imports.add('import ' + slot.asEnum.enumPackage + ';')
		}
		
		return slot.toJavaTypeDTO
	}
	
	def static getDistinctSlotsByEntityName(EList<Slot> slots) {
		val onlyEntitySlots = slots.filter[it.isEntity].toList
		val List<Slot> distinctByEntityNameSlots = new ArrayList()
		onlyEntitySlots.forEach[slot | 
			// Deixa adicionar apenas 1 slot apontando para a mesma entidade, e
			// não deixa adicionar slot se ele é do mesmo tipo da entidade owner dele.
			val slotAsEntityName = slot.asEntity.name
			val canAdd = (slotAsEntityName != slot.ownerEntity.name) && !distinctByEntityNameSlots.exists[it.asEntity.name == slotAsEntityName]
			if (canAdd) {
				distinctByEntityNameSlots.add(slot)
			}
		]
		
		distinctByEntityNameSlots
	}
	
	def static String resolveSlotAutocompleteImport(Slot slot) {
		if (slot.isEntity) { // If slot is an entity, returns its autocomplete class name version.
			val entity = slot.asEntity
			val autoCompleteName = entity.toAutoCompleteName
			val entityPackage = entity.package
			return 'import ' + entityPackage + '.' + autoCompleteName + ';'
		}
		return '<slot is not an entity>'
	}
	
	def static String resolveSlotAutocompleteImportForWeb(Slot slot) {
		if (slot.isEntity) { // If slot is an entity, returns its autocomplete class name version.
			val entity = slot.asEntity
			val autoCompleteName = entity.toAutoCompleteName
			//val entityPackage = entity.package
			val result = '''import { «autoCompleteName» } from './«entity.toEntityWebModelNameWithPah»';'''
			//println('result: ' + result)
			return result
		}
		return '<slot is not an entity>'
	}
	
	def static String resolveSlotRepositoryImport(Slot slot) {
		if (slot.isEntity) { // If slot is an entity, returns its autocomplete class name version.
			val entity = slot.asEntity
			val repositoryName = entity.toRepositoryName
			val entityPackage = entity.package
			return 'import ' + entityPackage + '.' + repositoryName + ';'
		}
		return '<slot is not an entity>'
	}
	
	
	
	def static String resolveAutocompleteFieldName(Slot slot) {
		if (slot.isEntity) { // If slot is an entity, returns first string auto complete key configurated.
			val entity = slot.asEntity
			val autoCompleteSlot = entity.slots.filter[it.isAutoCompleteKey && it.isString].head
			if (autoCompleteSlot !== null) {
				return slot.fieldName + '.' + autoCompleteSlot.fieldName
			}
		}
		return slot.fieldName
	}
	
	def static String resolveAutocompleteFieldNameForWeb(Slot parentSlot, Slot slot) {
		var fieldName = parentSlot.fieldName + '.' + slot.fieldName
		if (slot.isEntity) { // If slot is an entity, returns first string auto complete key configurated.
			val entity = slot.asEntity
			val autoCompleteSlot = entity.slots.filter[it.isAutoCompleteResult && !it.isHiddenSlot].head
			if (autoCompleteSlot !== null) {
				fieldName += '.' + autoCompleteSlot.fieldName
				return autoCompleteSlot.resolveAutocompleteFieldNameForWebType(fieldName)
			}
		}
		return slot.resolveAutocompleteFieldNameForWebType(fieldName)
	}
	
	def static String getAutocompleteFieldNameForWeb(Slot parentSlot, Slot slot) {
		var fieldName = parentSlot.fieldName + '.' + slot.fieldName
		if (slot.isEntity) { // If slot is an entity, returns first string auto complete key configurated.
			val entity = slot.asEntity
			val autoCompleteSlot = entity.slots.filter[it.isAutoCompleteResult && !it.isHiddenSlot].head
			if (autoCompleteSlot !== null) {
				fieldName += '.' + autoCompleteSlot.fieldName
				return fieldName
			}
		}
		return fieldName
	}
	
	def static resolveAutocompleteFieldNameForWebType(Slot slot, String fieldName) {
		if (slot.isDate) {
			 return '''moment(«fieldName»).format('DD/MM/YYYY')'''.toString
		}
		else if (slot.isDateTime) {
			 return '''moment(«fieldName»).format('DD/MM/YYYY H:m')'''.toString
		}
		else if (slot.isTime) {
			 return '''moment(«fieldName»).format('H:m:s')'''.toString
		}
		else {
			return '''«fieldName»'''
		}
	}
	
	def static getFieldName(Slot slot) {
		slot.name.toFirstLower
	}
	
	def static toLambdaGetMethod(Slot slot) {
		val entity = slot.ownerEntity
		
		//val result = entity.toDtoName + '::get' + slot.name.toFirstUpper
		
		val result = entity.toDtoName.toLambdaGetMethod(slot)
		result
	}
	
	def static toLambdaGetMethod(String objectClassName, Slot slot) {
		val result = objectClassName + '::get' + slot.name.toFirstUpper
		result
	}
	
	def static resolveFieldInitializationValue(Slot slot) {
		var value = ''
		
		if (slot.isSmallint) {
			value = '0'
		}
		
		if (!value.empty) {
			''' = «value»'''
		}
		else {
			''''''
		}
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
	
	def static toSlotAutoCompleteName(Slot slot) {
		val entity = slot.asEntity
		val name = entity.fieldName + slot.fieldName.toFirstUpper + 'AutoComplete'
		name
	}
	
	def static toAutoCompleteImplName(Entity entity) {
		val name = entity.toAutoCompleteClassName + 'Impl'
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
		«IF noArgsConstructor»
		
		public «className»() {
			// Contructor for reflexion, injection, Jackson, QueryDSL, etc proposal.
		}
		«ENDIF»
		«IF allArgsConstructor»
		
		public «className»(«slots.map[it.buildFieldAndType].join(', ')») {
			«slots.map[it.buildFieldThis].join('\n')»
		}
		«ENDIF»
		'''
	}
	
	def static String buildFieldThis(Slot slot) {
		val fileName = slot.name.toFirstLower
		'''this.«fileName» = «fileName»;'''.toString
	}
	
	
	
	def static CharSequence buildField(Slot slot) {
		'''private «slot.toJavaTypeDTO» «slot.name.toFirstLower»;'''
	}
	
	def static String buildFieldAndType(Slot slot) {
		'''«slot.toJavaTypeForEntityEvent» «slot.name.toFirstLower»'''.toString
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
	
	def static toAutoCompleteOnBlurMethodName(Slot slot) {
		slot.toAutoCompleteName + 'OnBlur'
	}
	
	def static toRuleWithSlotAppyStyleClassMethodName(Slot slot) {
		val name = 'rule' + slot.fieldName.toFirstUpper + 'AppyStyleClass'
		name
	}
	
	def static toRuleWithSlotAppyMathExpressionMethodName(Slot slot) {
		val name = 'rule' + slot.ownerEntity.fieldName.toFirstUpper + slot.name.toFirstUpper + 'OnAppyMathExpression'
		name
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
	
	def static getDefaultSortField(Entity entity) {
		val slot = entity.slots.tail.findFirst[it.hasSort] ?: entity.id
		slot.fieldName
	}
	
	def static String getDefaultSortFieldOrderBy(Entity entity) {
		val slot = entity.slots.tail.findFirst[it.hasSort] ?: entity.id
		var orderBy = '1'
		if (slot.hasSort) {
			orderBy = if(slot.sortASC) '1' else '0'
		}
		orderBy
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
	
	def static getEntityFieldName(Entity entity) {
		entity.name.toFirstLower + "Entity"
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
		'''«obj.buildMethodGet(slot)» != null ? «obj.buildMethodGet(slot)».«slot.asEntity.id.buildMethodGet» : null'''
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
		public «slot.toJavaType» get«name»() {
			return «name.toFirstLower»;
		}
		''' 
	}
	
	def static CharSequence getGetMethod(Slot slot, String prefix, String suffix) {
		val name = prefix.toFirstUpper + slot.name.toFirstUpper + suffix?.toFirstUpper
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
		
		public Boolean get«name»() {
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
		val name = slot.name.toFirstUpper + (suffix?.toFirstUpper ?: '')
		val nameFirstLower = name.toFirstLower
		'''
		public void set«name»(«slot.toJavaType» «nameFirstLower») {
			this.«nameFirstLower» = «nameFirstLower»;
		}
		''' 
	}
	
	def static CharSequence getSetMethod(Slot slot, String prefix, String suffix) {
		val name = prefix.toFirstUpper + slot.name.toFirstUpper + suffix?.toFirstUpper
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
	
	def static getMethod2(Slot slot) {
		'get' + slot.name.toFirstUpper + '(' + ')'
	}
	
	def static getIdGetMethod(Entity entity) {
		'get' + entity.id.name.toFirstUpper + '(' + ')'
	}
	
	def static buildMethodSet(Slot slot, String param) {
		slot.name.buildMethodSet(param)
	}
	
	def static buildMethodSet(Slot slot, String obj, String param) {
		obj + '.' + slot.name.buildMethodSet(param)
	}
	
	def static CharSequence buildMethodSetForTypeScript(Slot slot, String value) {
		// e.g.: this.caixa.dataHoraFechamento = moment().toDate();
		val entityFieldName = slot.ownerEntity.fieldName
		'''
		this.«entityFieldName».«slot.fieldName» = «value»;
		'''
	}
	
	def static String buildRememberValuesMethodName(Entity entity) {
		val result = entity.fieldName + 'RememberValues'
		result
	}
	
	def static String buildApplyRememberValuesMethodName(Entity entity) {
		val result = entity.fieldName + 'ApplyRememberValues'
		result
	}
	
	def static String buildRememberValueEntityField(Entity entity) {
		val result = entity.fieldName + 'RememberValue'
		result
	}
	
	def static String buildRememberValueField(Slot slot) {
		val entity = slot.ownerEntity
		
		val result = 'this.' + entity.buildRememberValueEntityField + '.' + slot.fieldName
		result
	}
	
	def static CharSequence buildAssignFieldForRememberValue(Slot slot) {
		val entityFieldName = slot.ownerEntity.fieldName
		val value = slot.buildRememberValueField
		'''
		this.«entityFieldName».«slot.fieldName» = «value»;
		'''
	}
	
	def static CharSequence buildApplyFieldFromRememberValue(Slot slot) {
		val entityFieldName = slot.ownerEntity.fieldName
		val value = slot.buildRememberValueField
		'''
		«value» = this.«entityFieldName».«slot.fieldName»;
		'''
	}
	
	def static String toWebFieldName(Slot slot) {
		// e.g.: this.caixaDiario.caixaDiarioSituacao
		val entityAsFieldName = slot.ownerEntity.fieldName
		'''this.«entityAsFieldName».«slot.fieldName»'''
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
	
	def static toRuleActionName(RuleAction ruleAction, String defautName) {
		ruleAction?.actionName ?: defautName
	}
	
	def static toRuleActionWhenConditionName(String actionName) {
		actionName + 'WhenCondition'
	}
	
	def static toEntityRuleFormActionsFunctionName(Entity entity, RuleFunction func) {
		entity.fieldName + "RuleFunction" + func.methodName.toFirstUpper
	}
	
	def static toRuleFormActionsWithFunctionName(Entity entity) {
		entity.name.toFirstUpper + "RuleFunctions"
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
	
	def static toServiceTestName(Entity entity) {
		entity.name.toFirstUpper + "ServiceTest"
	}
	
	def static toServiceTestConfigurationName(Entity entity) {
		entity.name.toFirstUpper + "ServiceTestConfig"
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
		else if (basicType instanceof SmallintType) {
			"short"
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
		else if (basicType instanceof SmallintType) {
			"number"
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
	
	public static def boolean isEqualTo(Slot slot) {
		FilterOperatorEnum.IS_EQUAL_TO.equals(slot.listFilter.filterOperator.filterOperatorEnum)
	} 
	
	// BEGIN For tests
	
		
	
	// END For tests
	
	def static String toServiceConstantsName2(Service service) {
		service.domain.toCamelCase + service.name.toCamelCase + "Constants"
	}
	
	def static String getImportServiceConstants2(Service service) {
		'import ' + service.servicePackage + '.' + service.toServiceConstantsName2 + ';'
	}
	
	def static String getImportServiceConstants2(Entity entity) {
		val service = entity.service
		'import ' + service.servicePackage + '.' + service.toServiceConstantsName2 + ';'
	}
}