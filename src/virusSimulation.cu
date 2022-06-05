#include "UAMMDstructured.cuh"

using namespace uammd::structured;
    
using Units = UnitsSystem::KCALMOL_A;

using ffGeneric = forceField::Generic::Generic<Units,
                                               Types::BASIC,
                                               conditions::excludedIntraInterChargedInter>;

using SIMfree = Simulation<ffGeneric,
                           SteepestDescent,
                           LangevinNVT::BBK>;

int main(int argc, char** argv){

    auto sys = std::make_shared<uammd::System>();
    
    ullint seed = 0xf31337Bada55D00dULL^time(NULL);
    sys->rng().setSeed(seed);

    uammd::InputFile in(argv[1]);

    std::shared_ptr<SIMfree> sim = std::make_shared<SIMfree>(sys,in);
    
    auto pd  = sim->getParticleData();

    std::map<int,std::shared_ptr<uammd::ParticleGroup>> simGroups;
    {
        std::set<int> simList;
        {
            auto simId = pd->getSimulationId(uammd::access::location::cpu,uammd::access::mode::read);

            fori(0,pd->getNumParticles()){
                simList.emplace(simId[i]);
            }
        }
        
        for(const int& s : simList){
            selectors::simulationId selector(s);

            auto pgs = std::make_shared<uammd::ParticleGroup>(selector,
                                                              pd,
                                                              sys,
                                                              "simId_"+std::to_string(s));
            simGroups[s]=pgs;
        }
    }
        
    {
        WriteStep<Units>::Parameters paramBase = WriteStep<Units>::inputFileToParam(in);

        int interval = std::stoi(in.getOption("nStepsWriteInterval",uammd::InputFile::Required).str());

        for(auto pg : simGroups){    
            
            auto groupIndex  = pg.second->getIndexIterator(uammd::access::location::cpu);
            
            auto simId = pd->getSimulationId(uammd::access::location::cpu,uammd::access::mode::read);
            int  s = simId[groupIndex[0]];
            
            WriteStep<Units>::Parameters param = paramBase;
            param.outPutFilePath = paramBase.outPutFilePath+"_"+std::to_string(s);
            
            std::shared_ptr<WriteStep<Units>> wStep = std::make_shared<WriteStep<Units>>(sys,
                                                                                         pd,
                                                                                         pg.second,
                                                                                         interval,
                                                                                         param);

            wStep->setPBC(false);
            sim->addSimulationStep(wStep);
        }
    }

    sim->run();
    
    sys->finish();
    
    return EXIT_SUCCESS;
}
