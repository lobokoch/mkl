package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityListFilterAutoCompleteGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateAutoComplete]
	}
	
	def generateAutoComplete(Entity entity) {
		val slots = entity.slots.filter[it.isListFilterManyEntity]
		val basePakage = clientGenSourceFolder
		slots.forEach[ slot |
			val file = basePakage + entity.packagePath + '/' + slot.toAutoCompleteDTOName + '.java'
			generateFile(file, slot.generateEntityAutoComplete)
		]
	}
	
	def CharSequence generateEntityAutoComplete(Slot slot) {	
		val entity = slot.ownerEntity
		val slots = #[slot]
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public interface «slot.toAutoCompleteDTOName» {
		
			«slots.generateGetters»
		
		}
		'''
		package + /*imports +*/ body 
	}
	
	def CharSequence generateGetters(Iterable<Slot> slots) {
		'''
		«slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		'''
		«slot.toJavaTypeDTO» get«slot.name.toFirstUpper»();
		'''
	}
	
}