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
		val modelDir = entity.webEntityPath
		val entityFile = modelDir + entity.toEntityWebModelName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityModel)
	}
	
	
	def CharSequence doGenerateEntityModel(Entity entity) {
		entity.initializeEntityImports
		
		val body = '''
		«generateSortFieldModel»
		«generatePaginationFilterModel»
		«entity.generateEntityListFilterModel»
		«IF entity.hasListFilterMany»
		«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoCompleteModel].join»
		«entity.doGenerateEntityDTOModel»
		«ENDIF»
		
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		imports + body 
	}
	
	def CharSequence generateListFilterAutoCompleteModel(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		
		'''
		
		export class «autoComplateName» {
			«slot.fieldName»: «slot.toWebType»;
		}
		'''
	}
	
	// Begin DTO Model
	def CharSequence doGenerateEntityDTOModel(Entity entity) {
		'''
		
		export class «entity.toEntityDTOName» {
				
			«entity.generateFields»
			«/*entity.generateGetters*/»
			«/*entity.generateSetters*/»
		}
		'''
	}
	
	
	def CharSequence generateFields(Entity entity) {
		'''
		«entity.slots.map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		if (slot.isDTOFull) {
			entity.addImport("import { " + slot.asEntity.toEntityDTOName + " } from './" + slot.asEntity.toEntityWebModelName + "';")
		}
		//else if (slot.isDTOLookupResult) {
		else if (slot.isEntity) {
			entity.addImport("import { " + slot.asEntity.toEntityDTOName + " } from './" + slot.asEntity.toEntityWebModelName + "';")
		}
		else if (slot.isEnum) { 
			entity.addImport("import { " + slot.asEnum.name.toFirstUpper + " } from './" + slot.ownerEntity.toEntityWebModelName + "';")
			// entity.addImport('import ' + slot.asEnum.enumPackage + ';')
		}
		
		'''
		«IF slot.isEntity»
		«slot.fieldName»: «slot.asEntity.toEntityDTOName»;
		«ELSE»
		«slot.fieldName»: «slot.toWebType»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		«entity.slots.map[generateGetter].join('\r\n')»
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
		
		«entity.slots.map[generateSetter].join('\r\n')»
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
		    this.order = order = 0;
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
		
		export class «entity.toEntityListFilterName» extends PaginationFilter {
				
			«entity.generateListFilterFields»
		
		}
		'''
	}
	
	def CharSequence generateListFilterFields(Entity entity) {
		val slots = entity.slots.filter[it.hasListFilter]
		
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
		«fieldName»: «slot.toAutoCompleteDTOName»[];
		«ELSEIF isNotNull && isNull»
		«slot.isNotNullFieldName»: «slot.toWebType»;
		«slot.isNullFieldName»: «slot.toWebType»;
		«ELSEIF isNotNull»
		«slot.isNotNullFieldName»: «slot.toWebType»;
		«ELSEIF isNull»
		«slot.isNullFieldName»: «slot.toWebType»;
		«ELSEIF isBetween»
		«slot.toIsBetweenFromName»: «slot.toWebType»;
		«slot.toIsBetweenToName»: «slot.toWebType»;
		«ENDIF»
		'''
	}
	
}