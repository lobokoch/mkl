package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityDTOConverterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private static val ENTITY = 'entity'
	private static val DTO = 'dto'
	
	private static val TO_DTO = 'convertEntityToDto'
	private static val TO_ENTITY = 'convertDtoToEntity'
	
	private StringConcatenationExt builder
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateEntityDTOConverter]
	}
	
	def generateEntityDTOConverter(Entity entity) {
		entity.imports.clear
		try {
			val basePakage = serverGenSourceFolder
			val fileName = basePakage + entity.packagePath + '/' + entity.toDTOConverterName + '.java'
			generateFile(fileName, entity.generateDTOConverter)
		}
		finally {
			entity.imports.clear
		}
	}
	
	def CharSequence generateDTOConverter(Entity entity) {
		builder = new StringConcatenationExt()
		builder.addPackage(entity.package)
		
		builder.addImport('org.springframework.stereotype.Component')
		.addImport('org.modelmapper.ModelMapper')
		.addImport('org.modelmapper.convention.MatchingStrategies')
		
		builder
		.add('@Component')
		.add('public class ').concat(entity.toDTOConverterName).concat(' {')
		.add('	private final ModelMapper mapper;').ln
		.addIndent(entity.generateConstructor).ln
		.addIndent(entity.generateEntityToDto).ln
		.addIndent(entity.generateDtoToEntity).ln
		
		builder
		.add('}')
		
		
		val result = builder.build
		result
	}
	
	def CharSequence generateEntityToDto(Entity entity) {
		'''
		public «entity.toEntityDTOName» «TO_DTO»(«entity.toEntityName» «ENTITY») {
			«entity.toEntityDTOName» «DTO» = null;
			if («ENTITY» != null) {
				«DTO» = mapper.map(«ENTITY», «entity.toEntityDTOName».class);
			}
			return «DTO»;
		}
		'''
	}
	
	def CharSequence generateDtoToEntity(Entity entity) {
		'''
		public «entity.toEntityName» «TO_ENTITY»(«entity.toEntityDTOName» «DTO») {
			«entity.toEntityName» «ENTITY» = null;
			if («DTO» != null) {
				«ENTITY» = mapper.map(«DTO», «entity.toEntityName».class);
			}
			return «ENTITY»;
		}
		'''
	}
	
	def CharSequence generateConstructor(Entity entity) {
		//val entityDTOName = entity.toEntityDTOName
		//val entityName = entity.toEntityName
		val oneToOneBidirectionalSlots = entity.slots.filter[it.isOneToOne && it.isBidirectional]
		
		'''
		public «entity.toDTOConverterName»() {
			mapper = new ModelMapper();
			mapper.getConfiguration().setMatchingStrategy(MatchingStrategies.STANDARD);
			
			«IF ! oneToOneBidirectionalSlots.empty»
			«entity.generateTypeMapDtoToEntity»
			
			«entity.generate_Dto_AddMappings_Configure(oneToOneBidirectionalSlots)»
			«ENDIF»
			
		}
		'''
	}
	
	def CharSequence generateTypeMapDtoToEntity(Entity entity) {
		val entityDTOName = entity.toEntityDTOName
		val entityName = entity.toEntityName
		builder.addImport('org.modelmapper.TypeMap')
		
		'''
		//DTO to Entity tratatives
		TypeMap<«entityDTOName», «entityName»> typeMapDtoToEntity = mapper.createTypeMap(«entityDTOName».class, «entityName».class);
		'''
	}
	
	def CharSequence generate_Dto_AddMappings_Configure(Entity entity, Iterable<Slot> slots) {
		val entityDTOName = entity.toEntityDTOName
		val entityName = entity.toEntityName
		builder.addImport('org.modelmapper.PropertyMap')
		
		'''
		PropertyMap<«entityDTOName», «entityName»> pmConfigure = new PropertyMap<«entityDTOName», «entityName»>() {
					
			@Override
			protected void configure() {
				«slots.map[generate_DestinationSkip].join»
			}
		};
				
		typeMapDtoToEntity.addMappings(pmConfigure);
		'''
	}
	
	def Object generate_DestinationSkip(Slot slot) {
		'''
		skip(destination.«slot.buildMethodGet».«slot.relationOppositeSlot.buildMethodGet»);
		'''
	}
	
	//Examples: https://github.com/modelmapper/modelmapper/issues/37
	def CharSequence generate_Dto_setPostConverter(Entity entity, Iterable<Slot> slots) {
		val entityDTOName = entity.toEntityDTOName
		val entityName = entity.toEntityName
		'''
		//Post convert operations
		Converter<«entityDTOName», «entityName»> dtoPostConverter = new Converter<«entityDTOName», «entityName»>() {
		
			@Override
			public «entityName» convert(MappingContext<«entityDTOName», «entityName»> context) {
				/*«entityName» entity = context.getDestination();
				
				List<DependentEntity> dependents = entity.getDependents();
				if (dependents != null) {
					dependents.forEach(it -> it.setEmployee(entity));
				}
		
				entity.getAddress().setEmployee(entity);*/
				
				return context.getDestination();
			}
		};
		
		typeMapDtoToEntity.setPostConverter(dtoPostConverter);
		'''
	}
	
}