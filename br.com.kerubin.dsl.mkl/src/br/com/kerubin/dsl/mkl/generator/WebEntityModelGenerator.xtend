package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityModelGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateEntityModel]
	}
	
	def generateEntityModel(Entity entity) {
		val entityDir = entity.webEntityPath
		val entityFile = entityDir + entity.toEntityWebModelName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityModel)
	}
	
	
	def CharSequence doGenerateEntityModel(Entity entity) {
		entity.initializeEntityImports
		
		val body = '''
		«generateSortFieldModel»
		«generatePaginationFilterModel»
		«IF entity.hasListFilterMany»
		«entity.slots.filter[!mapped].filter[it.isListFilterMany].map[generateListFilterAutoCompleteModel].join»
		«ENDIF»
		«entity.generateEntityListFilterModel»
		«entity.generateEntityDTOModel(false)»
		«entity.generateEntityDefaultAutoComplete(true)»
		«entity.generateEntitySumFieldsModel»
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		imports + body 
	}
	
	def CharSequence generateEntityDefaultAutoComplete(Entity entity, boolean isAutoComplete) {
		val autoCompleteSlots = entity.slots.filter[!mapped].filter[it.isAutoCompleteResult || it.isAutoCompleteData || (entity.enableVersion && it.name.toLowerCase == 'version')]
		'''
		
		export class «entity.toAutoCompleteName» {
			«autoCompleteSlots.map[generateField(entity, isAutoComplete)].join»
		}
		'''
	}
	
	def CharSequence generateListFilterAutoCompleteModel(Slot slot) {
		val autoComplateName = slot.toAutoCompleteClassName
		
		'''
		
		export class «autoComplateName» {
			«slot.fieldName»: «slot.toWebType»;
		}
		'''
	}
	
	// Begin DTO Model
	def CharSequence generateEntityDTOModel(Entity entity, boolean isAutoComplete) {
		'''
		
		export class «entity.toEntityDTOName» {
			«entity.generateFields(isAutoComplete)»
		}
		'''
	}
	
	def CharSequence generateEntitySumFieldsModel(Entity entity) {
		'''
		
		export class «entity.toEntitySumFieldsName» {
			«entity.sumFieldSlots.map[generateSumField].join»
		}
		'''
	}
	
	def CharSequence generateSumField(Slot slot) {
		'''
		«slot.sumFieldName»: number;
		'''
	}
	
	def CharSequence generateFields(Entity entity, boolean isAutoComplete) {
		val slots = entity.slots.filter[!mapped]
		'''
		«slots.map[generateField(entity, isAutoComplete)].join»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity, boolean isAutoComplete) {
		var dtoModel = entity.toEntityWebModelNameWithPah(slot)
		var className = 'NONE'
		if (slot.isEntity) {
			className = if (isAutoComplete) slot.asEntity.toAutoCompleteName else slot.asEntity.toEntityDTOName
		} 
		
		if (slot.isDTOFull) {
			entity.addImport("import { " + slot.asEntity.toEntityDTOName + " } from './" + dtoModel + "';")
		}
		//else if (slot.isDTOLookupResult) {
		else if (slot.isEntity && slot.asEntity.isNotSameName(entity)) {
			entity.addImport("import { " + className + " } from './" + dtoModel + "';")
		}
		else if (slot.isEnum) { 
			val slotAsEnum = slot.asEnum
			entity.addImport('''import { «slotAsEnum.toDtoName» } from '«service.serviceWebEnumsPathName»';''')
		}
		
		'''
		«IF slot.isEntity»
		«slot.fieldName»: «className»;
		«ELSE»
		«slot.fieldName»: «slot.toWebType»«IF slot.hasDefaultValue» = «slot.defaultValue»«ENDIF»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		«entity.slots.filter[!mapped].map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		«IF slot.isToMany»
		get «slot.fieldName»(): «slot.toWebTypeDTO»[] {
		«ELSE»
		get «slot.fieldName»(): «slot.toWebTypeDTO» {
		«ENDIF»
			return this.«slot.fieldNameWeb»;
		}
		'''
	}
	
	def CharSequence generateSetters(Entity entity) {
		'''
		
		«entity.slots.filter[!mapped].map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		
		'''
		«IF slot.many && slot.isToMany»
		set «slot.fieldName»(value: «slot.toWebTypeDTO»[]) {
		«ELSE»
		set «slot.fieldName»(value: «slot.toWebTypeDTO») {
		«ENDIF»
			this.«slot.fieldName» = value;
		}
		'''
	}
	
	def void initializeEntityImports(Entity entity) {
		entity.imports.clear
	}
	
	def CharSequence getSlotsEntityImports(Entity entity) {
		'''
		«entity.slots.filter[it.isEntity].map[it | 
			val slotEntity = it.asEntity
			return "import " + slotEntity.package + "." + slotEntity.toEntityName + ";"
			].join('\r\n')»
		'''
	}
	
	// End DTO entity model
	
	// End DTO entity model
	
	def CharSequence generateSortFieldModel() {
		'''
		
		export class SortField {
		  field: string;
		  order: number;
		
		  constructor(field: string, order: number) {
		    this.field = field;
		    this.order = order;
		  }
		}
		'''
	}
	
	def CharSequence generatePaginationFilterModel() {
		'''
		
		export class PaginationFilter {
		  pageNumber: number;
		  pageSize: number;
		  sortField: SortField;
		
		  constructor() {
		    this.pageNumber = 0;
		    this.pageSize = 10;
		  }
		}
		'''
	}
	
	def CharSequence generateEntityListFilterModel(Entity entity) {
		'''
		
		export class «entity.toEntityListFilterClassName» extends PaginationFilter {
			«entity.generateListFilterFields»
		}
		'''
	}
	
	def CharSequence generateListFilterFields(Entity entity) {
		val slots = entity.slots.filter[!mapped].filter[it.hasListFilter]
		
		'''
		
		«slots.map[generateListFilterField].join('\r\n')»
		'''
	}
	
	def CharSequence generateListFilterField(Slot slot) {
		var fieldName = slot.fieldName
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
		
		val isMany = slot.isListFilterMany
		
		val isBetween = slot.isBetween 
		
		'''
		«IF isMany»
		«fieldName»: «slot.toAutoCompleteClassName»[];
		«ELSEIF isNotNull && isNull»
		«slot.isNotNullFieldName»: boolean;
		«slot.isNullFieldName»: boolean;
		«ELSEIF isNotNull»
		«slot.isNotNullFieldName»: boolean;
		«ELSEIF isNull»
		«slot.isNullFieldName»: boolean;
		«ELSEIF isBetween»
		«slot.toIsBetweenFromName»: «slot.toWebType»;
		«slot.toIsBetweenToName»: «slot.toWebType»;
		«ENDIF»
		'''
	}
	
}