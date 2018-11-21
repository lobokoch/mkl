package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

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
		val modelDir = entity.servicePath.getWebModelDir()
		val entityFile = modelDir + entity.toEntityWebModelName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityModel)
	}
	
	def CharSequence doGenerateEntityModel(Entity entity) {
		entity.initializeEntityImports
		
		val body = '''
		
		export class «entity.toEntityDTOName» {
		
			«entity.generateFields»
			«entity.generateGetters»
			«entity.generateSetters»
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		imports + body 
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
		else if (slot.isDTOLookupResult) {
			entity.addImport("import { " + slot.asEntity.toEntityDTOName + " } from './" + slot.asEntity.toEntityWebModelName + "';")
		}
		else if (slot.isEnum) { 
			entity.addImport("import { " + slot.asEnum.name.toFirstUpper + " } from './" + slot.ownerEntity.toEntityWebModelName + "';")
			// entity.addImport('import ' + slot.asEnum.enumPackage + ';')
		}
		
		'''
		«IF slot.isToMany»
		private «slot.name.toFirstLower»: «slot.toWebTypeDTO»[];
		«ELSE»
		private «slot.name.toFirstLower»: «slot.toWebType»;
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
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO»[] {
		«ELSE»
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO» {
		«ENDIF»
			return this.«slot.name.toFirstLower»;
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
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO»[]) {
		«ELSE»
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO») {
		«ENDIF»
			this.«slot.name.toFirstLower» = value;
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
	
	
}