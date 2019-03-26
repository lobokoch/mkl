package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*

class JavaEntityMakeCopiesGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateContaPagarSumFields]
	}
	
	def generateContaPagarSumFields(Entity entity) {
		val rules = entity.ruleMakeCopies
		if (rules.empty) {
			return
		}
		
		val basePakage = clientGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityMakeCopiesName + '.java'
		generateFile(entityFile, entity.doGenerateContaPagarMakeCopies(rules))
	}
	
	def CharSequence doGenerateContaPagarMakeCopies(Entity entity, Iterable<Rule> rules) {
		val rule = rules.head // Only the first
		
		entity.imports.clear
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public class «entity.toEntityMakeCopiesName» {
			
			«entity.generateFields(rule)»
			«entity.toEntityMakeCopiesName.generateNoArgsConstructor»
			«entity.generateGetters(rule)»
			«entity.generateSetters(rule)»
		
		}
		'''
		
		val imports = '''
		import javax.validation.constraints.Max;
		import javax.validation.constraints.Min;
		import javax.validation.constraints.NotBlank;
		import javax.validation.constraints.NotNull;
		'''
		
		package + imports + body 
	}
	
	def CharSequence generateFields(Entity entity, Rule rule) {
		val id = entity.id
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		
		'''
		@NotNull(message="'«id.name.toFirstUpper»' é obrigatório.")
		private «id.toJavaType» «id.fieldName»;
		
		@Min(value = 1, message = "A quantidade de cópias não pode ser menor que 1.")
		@Max(value = 10000, message = "A quantidade de cópias não pode ser maior que 10000.")
		private Long numberOfCopies;
		
		@Min(value = 1, message = "O intervalo não pode ser menor que 1.")
		@Max(value = 10000, message = "O intervalo não pode ser maior que 10000.")
		private Long referenceFieldInterval;
		
		@NotBlank(message = "O campo '«rule.getRuleMakeCopiesGrouperSlotName»' deve ser informado.")
		«grouperField.buildField»;
		'''
		
	}
	
	def CharSequence generateGetters(Entity entity, Rule rule) {
		val id = entity.id
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		
		'''
		
		«id.getGetMethod»
		
		public Long getNumberOfCopies() {
			return numberOfCopies;
		}
		
		public Long getReferenceFieldInterval() {
			return referenceFieldInterval;
		}
		
		«grouperField.getMethod»
		'''
		
	}
	
	def CharSequence generateSetters(Entity entity, Rule rule) {
		val id = entity.id
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		
		'''
		
		«id.setMethod»
		
		public void setNumberOfCopies(Long numberOfCopies) {
			this.numberOfCopies = numberOfCopies;
		}
		
		public void setReferenceFieldInterval(Long referenceFieldInterval) {
			this.referenceFieldInterval = referenceFieldInterval;
		}
		
		«grouperField.setMethod»
		'''
	}
}